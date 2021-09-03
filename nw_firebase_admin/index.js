const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');
const readline = require('readline');
const fs = require('fs');
const storageURI = 'gs://nature-wallpapers-8d315.appspot.com/';
let FieldValue = require('firebase-admin').firestore.FieldValue;

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: 'https://nature-wallpapers-8d315.firebaseio.com',
  storageBucket: 'nature-wallpapers-8d315.appspot.com',
});

const db = admin.firestore();
const storage = new Storage({
  keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS,
});
const storageBucket = 'nature-wallpapers-8d315.appspot.com';

const args = require('minimist')(process.argv.slice(2));
const fileName = args['fileName'] || 'files.txt';
if (!fileName) {
  console.log('Please provide fileName argument');
  process.exit(1);
}

const readInterface = readline.createInterface({
  input: fs.createReadStream(fileName),
  console: false,
});

// readInterface
//   .on('line', async (line) => {
//     await processLine(line);
//   })
//   .on('close', () => {
//     console.log('on close stream');
//     // dumpToFirestore(parentCatObj, curParent, categoryObj, curCat, imageList);
//   });

const options = {
  // contentType: 'image/jpeg',
  version: 'v2',
  action: 'read',
  expires: '12-12-2121',
};

const WALLP_PREFIX = 'wallpapers/';
const THUMB_PREFIX = 'thumbnails/';
const THUMB_CATS_DIR = 'categories/';
const COLLECTION = 'categories';
const WALLPAPERS = 'wallpapers';
const CAT_THUMB_IMAGE_NAME = 'cat_thumb.jpg';
const ROOT_ID = '_root_';
const ROOT_TITLE = 'root';

let catTree = new Map();
let imageList = [];
let curCategory = null;
let prevCategory = null;
let curParent = null;
let curAncestor = null;
let prevAncestor = null;

let debugLinesNum = 0;
let debugDocsUpdated = 0;
let debugWPAdded = 0;

async function dumpToFirestore(catTree) {
  for (const catId of catTree.keys()) {
    const catVal = catTree.get(catId);

    let futureList = [];
    let catDocRef = db.collection(COLLECTION).doc('all_categories');
    let wpDocRef = db.collection(WALLPAPERS);

    if (catVal.images.length > 0) {
      let imgIdsMap = {};
      for (const img of catVal.images) {
        imgIdsMap[img.id] = { ...img };
      }

      futureList.push(
        //update wallpapers collection
        updateWallpapers(wpDocRef, imgIdsMap)
      );
    }

    const catObj = {
      id: catVal.id,
      children: catVal.children,
      parent: catVal.parent,
      thumbUrl: catVal.thumbUrl,
      title: catVal.title,
    };

    futureList.push(
      //update categories document
      updateCollections(catDocRef, catObj)
    );

    await Promise.all(futureList);
  }
}

//update category document with children categories
async function updateCollections(docRef, docObject) {
  let doc = await docRef.get();
  let catsList = [];
  let category = null;

  if (!doc.exists) {
    console.log(`Creating document at ${docRef.path}`);
    await docRef.set({
      categories: [],
    });
  } else {
    catsList = doc.data().categories;
  }

  for (let index = 0; index < catsList.length; index++) {
    const cat = catsList[index];
    if (
      cat.hasOwnProperty(docObject.id) &&
      cat[docObject.id].id == docObject.id
    ) {
      category = cat[docObject.id];
      for (const child of docObject.children) {
        if (category.children.indexOf(child) == -1) {
          category.children.push(child);
        }
      }
      catsList[index][docObject.id] = category;
      break;
    }
  }

  if (category == null) {
    category = {};
    category[docObject.id] = docObject;
    catsList.push(category);
  }

  console.log(`Setting document for category: ${docObject.id}`);
  debugDocsUpdated++;
  try {
    return await admin.firestore().runTransaction(async (transaction) => {
      transaction.set(docRef, {
        categories: catsList,
      });
    });
  } catch (error) {
    console.log(
      `Error setting document for category: ${docObject.id} ${error}`
    );
  }
}

//update wallpapers collection
async function updateWallpapers(wpRef, wpObjectMap) {
  console.log(`Updating wallpapers collection at ${wpRef.path}`);
  let batch = db.batch();
  try {
    let docsInBatch = 0;
    for (const key in wpObjectMap) {
      if (wpObjectMap.hasOwnProperty(key)) {
        const element = wpObjectMap[key];
        debugWPAdded++;
        batch.set(wpRef.doc(`${key}`), element, { merge: true });
        if (++docsInBatch == 500) {
          await batch.commit();
          batch = db.batch();
          docsInBatch = 0;
        }
      }
    }
    return await batch.commit();
  } catch (error) {
    console.log(`Error updating wallpapers collection at ${wpRef.path}`, error);
  }
}

async function emptyCategoryObject(categoryTitle, categoryId, parentId) {
  try {
    var thumbUrl =
      categoryId == ROOT_ID
        ? ''
        : sanitizeUrl(
            await storage
              .bucket(storageBucket)
              .file(
                THUMB_PREFIX +
                  categoryId.replace(/_/g, '/') +
                  '/' +
                  CAT_THUMB_IMAGE_NAME
              )
              .getSignedUrl(options)
          );
  } catch (error) {
    console.log('Error retrieving signed URL for category thumbnail', error);
  }
  return {
    id: categoryId,
    children: [],
    parent: parentId,
    ancestors: [],
    images: [],
    thumbUrl: thumbUrl,
    title: categoryTitle,
  };
}

function sanitizeUrl(url) {
  if (url.length) {
    // return url[0].replace('storage.googleapis.com', 'storage.cloud.google.com');
    return url[0];
  }
}

function getIdFromArray(catsArray, category) {
  if (category == ROOT_ID) return ROOT_ID;

  let id = '';

  for (let index = 0; index < catsArray.length; index++) {
    id = index == 0 ? catsArray[index] : id + '_' + catsArray[index];
    if (catsArray[index] == category) break;
  }

  return id;
}

function getAncestorsFromArray(catsArray, category) {
  if (category == ROOT_ID) return [ROOT_ID];

  let ancestors = [ROOT_ID];

  for (let index = 0; index < catsArray.length; index++) {
    ancestors.push(getIdFromArray(catsArray, catsArray[index]));
    if (catsArray[index] == category) break;
  }

  return ancestors;
}

//create all categories from catsArray and set their parent-child releationships
async function createAllCatsInHierarchy(catsArray) {
  function getTitle(index) {
    let title = catsArray[index];
    title = title.charAt(0).toUpperCase() + title.slice(1);
    return title;
  }

  if (catsArray.length == 0 && !catTree.has(ROOT_ID)) {
    catTree.set(ROOT_ID, await emptyCategoryObject(ROOT_TITLE, ROOT_ID, null));
  } else {
    for (let index = 0; index < catsArray.length; index++) {
      let parent = index - 1 >= 0 ? catsArray[index - 1] : ROOT_ID;
      let curCat = catsArray[index];

      let curCatObj = catTree.has(getIdFromArray(catsArray, curCat))
        ? catTree.get(getIdFromArray(catsArray, curCat))
        : await emptyCategoryObject(
            getTitle(index),
            getIdFromArray(catsArray, curCat),
            index == 0
              ? ROOT_ID
              : getIdFromArray(catsArray, catsArray[index - 1])
          );

      if (index + 1 < catsArray.length) {
        let child = catsArray[index + 1];
        if (!curCatObj.children.includes(child)) {
          curCatObj.children.push(child);
        }
      }

      if (parent == ROOT_ID) {
        let rootObj = catTree.has(ROOT_ID)
          ? catTree.get(ROOT_ID)
          : await emptyCategoryObject(ROOT_TITLE, ROOT_ID, null);

        if (!rootObj.children.includes(curCat)) {
          rootObj.children.push(curCat);
        }
        catTree.set(ROOT_ID, rootObj);
      }

      catTree.set(getIdFromArray(catsArray, curCat), curCatObj);
    }
  }
}

async function processLine() {
  let lastLine = false;
  let prevCatsArray = [];
  for await (const line of readInterface) {
    if (line.includes(WALLP_PREFIX)) {
      debugLinesNum++;
      let relativePath = line.split(WALLP_PREFIX)[1];
      let catsArray = relativePath.split('/');

      let imgName = catsArray[catsArray.length - 1];
      let imgId = imgName.split('.')[0];

      if (imgName == CAT_THUMB_IMAGE_NAME) continue;

      //remove image name
      catsArray = catsArray.slice(0, -1);

      //ROOT
      if (catsArray.length == 0) {
        curParent = null;
        curCategory = ROOT_ID;
      } else if (catsArray.length > 0) {
        curAncestor = catsArray[0];
        curParent =
          catsArray.length - 2 >= 0 ? catsArray[catsArray.length - 2] : ROOT_ID;
        curCategory = catsArray[catsArray.length - 1];
      }

      //initial
      if (!prevCategory) {
        prevCategory = curCategory;
        prevParent = curParent;
        prevAncestor = curAncestor;
        prevCatsArray = catsArray;
      }

      if (curCategory != prevCategory) {
        await createAllCatsInHierarchy(prevCatsArray);

        //current category changed, so save list of images from previous parsed category
        let categoryObj = catTree.get(
          getIdFromArray(prevCatsArray, prevCategory)
        );
        categoryObj.images = categoryObj.images.concat(imageList);
        categoryObj.ancestors = getAncestorsFromArray(
          prevCatsArray,
          prevCategory
        );
        catTree.set(getIdFromArray(prevCatsArray, prevCategory), categoryObj);
        imageList = [];
      }
      // if (prevAncestor != curAncestor) {
      // await dumpToFirestore(catTree);
      //remove all except root
      // for (const catKey of catTree.keys()) {
      //   if (catKey != ROOT_ID) {
      //     catTree.delete(catKey);
      //   }
      // }
      // }

      // process new image
      try {
        var urls = await Promise.all([
          storage
            .bucket(storageBucket)
            .file(THUMB_PREFIX + relativePath)
            .getSignedUrl(options),
          storage
            .bucket(storageBucket)
            .file(WALLP_PREFIX + relativePath)
            .getSignedUrl(options),
        ]);
      } catch (error) {
        console.log('Error retrieving signed URLs', error);
      }
      thumbUrl = sanitizeUrl(urls[0]);
      imageUrl = sanitizeUrl(urls[1]);

      imageList.push({
        id: imgId,
        category: getIdFromArray(catsArray, curCategory),
        parent: getIdFromArray(catsArray, curParent),
        ancestors: getAncestorsFromArray(catsArray, curCategory),
        imageName: imgName,
        relativePath: relativePath,
        likes: {},
        likesNum: 0,
        timestamp: admin.firestore.Timestamp.fromDate(new Date()),
        imageUrl: imageUrl,
        thumbUrl: thumbUrl,
      });

      prevCategory = curCategory;
      prevParent = curParent;
      prevAncestor = curAncestor;
      prevCatsArray = catsArray;
      lastLine = true;
    } else {
      lastLine = false;
    }
  }
  if (lastLine) {
    await createAllCatsInHierarchy(prevCatsArray);

    let categoryObj = catTree.get(getIdFromArray(prevCatsArray, prevCategory));
    categoryObj.images = categoryObj.images.concat(imageList);
    imageList = [];
    categoryObj.ancestors = getAncestorsFromArray(prevCatsArray, prevCategory);

    catTree.set(getIdFromArray(prevCatsArray, prevCategory), categoryObj);

    await dumpToFirestore(catTree);

    console.log(
      `\nProcessed\n\tLines: ${debugLinesNum}\n\tCategories updated: ${debugDocsUpdated}\n\tWallpapers added: ${debugWPAdded}`
    );
  }
}

processLine();
