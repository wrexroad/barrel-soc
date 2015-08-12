var schedule = require('node-schedule');
var assert = require('assert')
var MongoClient = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectID;
var url = 'mongodb://localhost:27017/barrel';
var rawCollectionNames = new RegExp(
   /(misc|ephm|hkpg|magn|rcnt|fspc)[1-3][A-Z]/
);
var lastRebinTime = {};

var getLatestData = function() {
   MongoClient.connect(url, function(err, db) {
      assert.equal(null, err);
      db.collections(function(err, collections) {
         assert.equal(null, err);
         assert.ok(collections.length > 0);
         collections.forEach(function(collection) {
            var name, type, payload;
           
            name = (collection.namespace.match(rawCollectionNames)||[])[0];
           
            if (name) {
               payload = name.substr(4);
               type = name.substr(0, 4);

               collection.find({"_id" : {"$gt" : lastRebinTime[type] || 0}}).
                  toArray(function(err, docs) {
                     var binLvl;

                     if(err) {
                        console.error(err);
                     }
                     
                     lastRebinTime[name] = +(new Date()) / 1000;
                     
                     for (binLvl = 1; binLvl <= 16; binLvl++) {
                        docs = rebinner[type](payload, docs, binLvl);
                     }
                  });
            }
         }); 
      });
   });
};

var rebinner = {
   hkpg : function(payload, docs, binLvL) {
      var
         numDocs = docs.length,
         binWidth = Math.pow(2, binLvL),
         loVal = {},
         hiVal = {},
         rebinned = [],
         doc_i, bin_i, var_i, thisBinId, lastBinId, hkpg;

      if (binLvL < 7) {
         //binning level too low, there would be less than 1 record per bin
         return docs;
      }
      if (!numDocs) {
         return null;
      }
      
      //set the first value of 'binId' and start an empty document.
      thisBinId = lastBinId = docs[0]._id - (docs[0]._id % binWidth); 

      for (doc_i = 0, bin_i = 0; doc_i < numDocs; doc_i++) {
         hkpg = docs[doc_i].hkpg;
         //check for a new bin
         thisBinId = docs[doc_i]._id - (docs[doc_i]._id % binWidth);
         if (thisBinId != lastBinId) {
            rebinned[bin_i] = {
               _id: thisBinId, hkpg: {}
            };
            rebinned[bin_i + 1] = {
               _id: thisBinId + (binWidth / 2), hkpg: {}
            };
            for (var_i in hkpg) {
               //save the min and the max as two neighboring points
               rebinned[bin_i].hkpg[var_i] = +loVal[var_i];
               rebinned[bin_i + 1].hkpg[var_i] = +hiVal[var_i];
            }
            loVal = {};
            hiVal = {};
            bin_i += 2;
         }
         
         //check for min and max in all hkpg values
         for (var_i in hkpg) {
            if (+hkpg[var_i] || hkpg[var_i] === 0) {
               if (!(loVal[var_i] < hkpg[var_i])) {
                  loVal[var_i] = hkpg[var_i];
               }
               if (!(hiVal[var_i] > hkpg[var_i])) {
                  hiVal[var_i] = hkpg[var_i];
               }
            }
         } 
      
         lastBinId = thisBinId;
      }
      
      //pickup the last incomplete bin
      rebinned[bin_i] = {
         _id: thisBinId, hkpg: {}
      };
      rebinned[bin_i + 1] = {
         _id: thisBinId + (binWidth / 2), hkpg: {}
      };
      for (var_i in hkpg) {
         rebinned[bin_i].hkpg[var_i] = +loVal[var_i];
         rebinned[bin_i + 1].hkpg[var_i] = +hiVal[var_i];
      }

      return rebinned;
   },
   rcnt : function(payload, docs, binLvL) {
      var
         numDocs = docs.length,
         binWidth = Math.pow(2, binLvL),
         rcnt = {},
         loVal = {},
         hiVal = {},
         rebinned = [],
         doc_i, bin_i, thisBinId, lastBinId;

      if (binLvL < 3) {
         //binning level too low, there would be less than 1 record per bin
         return docs;
      }
      if (!numDocs) {
         return null;
      }
      
      //set the first value of 'binId' and start an empty document.
      thisBinId = lastBinId = docs[0]._id - (docs[0]._id % binWidth); 

      for (doc_i = 0, bin_i = 0; doc_i < numDocs; doc_i++) {
         thisBinId = docs[doc_i]._id - (docs[doc_i]._id % binWidth);
         if (thisBinId != lastBinId) {
            rebinned[bin_i] = {
               _id: thisBinId, rcnt: {}
            };
            rebinned[bin_i + 1] = {
               _id: thisBinId + (binWidth / 2), rcnt: {}
            };
            rebinned[bin_i].rcnt = {
               '0' : +loVal['0'],
               '1' : +loVal['1'],
               '2' : +loVal['2'],
               '3' : +loVal['3']
            };
            rebinned[bin_i + 1].rcnt = {
               '0' : +hiVal['0'],
               '1' : +hiVal['1'],
               '2' : +hiVal['2'],
               '3' : +hiVal['3']
            };

            loVal = {};
            hiVal = {};
            bin_i += 2;
         }
         
         if (+rcnt['0'] || rcnt['0'] === 0) {
            if (!(loVal['0'] < rcnt['0'])) {
               loVal['0'] = rcnt['0'];
            };
            if (!(hiVal['0'] > rcnt['0'])) {
               hiVal['0'] = rcnt['0'];
            };
         }
   
         if (+rcnt['1'] || rcnt['1'] === 0) {
            if (!(loVal['1'] < rcnt['1'])) {
               loVal['1'] = rcnt['1'];
            };
            if (!(hiVal['1'] > rcnt['1'])) {
               hiVal['1'] = rcnt['1'];
            };
         }
   
         if (+rcnt['2'] || rcnt['2'] === 0) {
            if (!(loVal['2'] < rcnt['2'])) {
               loVal['2'] = rcnt['2'];
            };
            if (!(hiVal['2'] > rcnt['2'])) {
               hiVal['2'] = rcnt['2'];
            };
         }
   
         if (+rcnt['3'] || rcnt['3'] === 0) {
            if (!(loVal['3'] < rcnt['3'])) {
               loVal['3'] = rcnt['3'];
            };
            if (!(hiVal['3'] > rcnt['3'])) {
               hiVal['3'] = rcnt['3'];
            };
         }
      
         lastBinId = thisBinId;
      }
      
      rebinned[bin_i] = {
         _id: thisBinId, rcnt: {}
      };
      rebinned[bin_i + 1] = {
         _id: thisBinId + (binWidth / 2), rcnt: {}
      };
      rebinned[bin_i].rcnt = {
         '0' : +loVal['0'],
         '1' : +loVal['1'],
         '2' : +loVal['2'],
         '3' : +loVal['3']
      };
      rebinned[bin_i + 1].rcnt = {
         '0' : +hiVal['0'],
         '1' : +hiVal['1'],
         '2' : +hiVal['2'],
         '3' : +hiVal['3']
      };

      return rebinned;
   },
   ephm : function(payload, docs, binLvL) {
      var rebinned = [];
      if (binLvL < 3) {
         return;
      }
      return rebinned;
   },
   misc : function(payload, docs, binLvL) {
      var rebinned = [];
      if (binLvL < 2) {
         return docs;
      }
      return rebinned;
   },
   magn : function(payload, docs, binLvL) {
      var rebinned = [];
      return rebinned;
   },
   fspc : function(payload, docs, binLvL) {
      var rebinned = [];
      return rebinned;
   }
};

var j = schedule.scheduleJob('42 * * * *', function(){
    console.log('The answer to life, the universe, and everything!');
});

getLatestData();
