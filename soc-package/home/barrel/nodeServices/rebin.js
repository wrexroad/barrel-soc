var schedule = require('node-schedule');
var assert = require('assert')
var MongoClient = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectID;
var url = 'mongodb://localhost:27017/barrel';
var rawCollectionNames = new RegExp(
   /(misc|ephm|hkpg|magn|rcnt|fspc)[1-3][A-Z]$/
);
var lastRebinDay = {};

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

               collection.find({"_id" : {"$gte" : lastRebinDay[name] || 0}}).
                  toArray(function(err, docs) {
                     var
                        bulkOps = [],
                        binLvl, doc_i;

                     if(err) {
                        console.error(err);
                        return;
                     }
                     
                     lastRebinDay[name] = +(new Date()) / 1000;
                     lastRebinDay[name] =
                        lastRebinDay[name] - lastRebinDay[name] % 86400;
                     
                     for (binLvl = 1; binLvl <= 16; binLvl++) {
                        docs = rebinner[type](payload, docs, binLvl);
                        console.log(
                           "Rebinned " +  (docs || []).length +
                           " docs for " + name + "." + binLvl
                        );
                        
                        if (!docs || !docs.length) {
                           continue;
                        } 
                        //first we need to delete any old docs for this time span
                        bulkOps = [{
                           deleteMany: {
                              filter: {
                                 $and: [
                                    {_id: {$gte: docs[0]._id}},
                                    {_id: {$lte: docs[docs.length - 1]._id}}
                                 ]
                              }
                           }
                        }];

                        //create insert operations for all of the new docs
                        for (doc_i = 0; doc_i < docs.length; doc_i++) {
                           bulkOps.push({
                              insertOne: {document:  docs[doc_i]}
                           });
                        }
                        //preform the bulk operations
                        db.collection(name + "." + binLvl).
                           bulkWrite(bulkOps, function(err, r) {
                              if (err) {console.error(err);}
                           });
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
         record = {},
         loVal = {},
         hiVal = {},
         rebinned = [],
         doc_i, bin_i, var_i, thisBinId, prevBinId, value;

      if (binLvL < 7) {
         //binning level too low, there would be less than 1 record per bin
         return docs;
      }
      if (!numDocs) {
         return null;
      }
      
      //set the first value of 'binId' and start an empty document.
      thisBinId = prevBinId = docs[0]._id - (docs[0]._id % binWidth); 

      for (doc_i = 0, bin_i = 0; doc_i < numDocs; doc_i++) {
         for (var_i = 0; var_i < 40; var_i++) {
            record['hkpg' + var_i] = +docs[doc_i]['hkpg' + var_i];
         };

         thisBinId = docs[doc_i]._id - (docs[doc_i]._id % binWidth);
         if (thisBinId != prevBinId) {
            rebinned[bin_i] = {
               _id: prevBinId, gps: {}
            };
            rebinned[bin_i + 1] = {
               _id: prevBinId + (binWidth / 2), gps: {}
            };
            for (var_i in record) {
               rebinned[bin_i][var_i] = +loVal[var_i];
               rebinned[bin_i+ 1][var_i] = +hiVal[var_i];
            }

            loVal = {};
            hiVal = {};
            bin_i += 2;
            prevBinId = thisBinId;
         }
         
         for (var_i in record) {
            value = record[var_i];
            if (value || value === 0) {
               if (!(loVal[var_i] < value)) {
                  loVal[var_i] = value;
               };
               if (!(hiVal[var_i] > value)) {
                  hiVal[var_i] = value;
               };
            }
         }
      }
      
      rebinned[bin_i] = {
         _id: thisBinId, gps: {}
      };
      rebinned[bin_i + 1] = {
         _id: thisBinId + (binWidth / 2), gps: {}
      };
      for (var_i in record) {
         rebinned[bin_i][var_i] = +loVal[var_i];
         rebinned[bin_i+ 1][var_i] = +hiVal[var_i];
      }

      return rebinned;
   },
   rcnt : function(payload, docs, binLvL) {
      var
         numDocs = docs.length,
         binWidth = Math.pow(2, binLvL),
         record = {},
         loVal = {},
         hiVal = {},
         rebinned = [],
         doc_i, bin_i, thisBinId, prevBinId, value, var_i;

      if (binLvL < 3) {
         //binning level too low, there would be less than 1 record per bin
         return docs;
      }
      if (!numDocs) {
         return null;
      }
      
      //set the first value of 'binId' and start an empty document.
      thisBinId = prevBinId = docs[0]._id - (docs[0]._id % binWidth); 

      for (doc_i = 0, bin_i = 0; doc_i < numDocs; doc_i++) {

         record = {
            rcnt0: +docs[doc_i].rcnt0,
            rcnt1: +docs[doc_i].rcnt1,
            rcnt2: +docs[doc_i].rcnt2,
            rcnt3: +docs[doc_i].rcnt3
         };

         thisBinId = docs[doc_i]._id - (docs[doc_i]._id % binWidth);
         if (thisBinId != prevBinId) {
            rebinned[bin_i] = {
               _id: prevBinId, gps: {}
            };
            rebinned[bin_i + 1] = {
               _id: prevBinId + (binWidth / 2), gps: {}
            };
            for (var_i in record) {
               rebinned[bin_i][var_i] = +loVal[var_i];
               rebinned[bin_i+ 1][var_i] = +hiVal[var_i];
            }

            loVal = {};
            hiVal = {};
            bin_i += 2;
            prevBinId = thisBinId;
         }
         
         for (var_i in record) {
            value = record[var_i];
            if (value || value === 0) {
               if (!(loVal[var_i] < value)) {
                  loVal[var_i] = value;
               };
               if (!(hiVal[var_i] > value)) {
                  hiVal[var_i] = value;
               };
            }
         }
      }
      
      rebinned[bin_i] = {
         _id: thisBinId, gps: {}
      };
      rebinned[bin_i + 1] = {
         _id: thisBinId + (binWidth / 2), gps: {}
      };
      for (var_i in record) {
         rebinned[bin_i][var_i] = +loVal[var_i];
         rebinned[bin_i+ 1][var_i] = +hiVal[var_i];
      }

      return rebinned;
   },
   ephm : function(payload, docs, binLvL) {
      var
         numDocs = docs.length,
         binWidth = Math.pow(2, binLvL),
         record = {},
         loVal = {},
         hiVal = {},
         rebinned = [],
         doc_i, bin_i, thisBinId, prevBinId, value, var_i;

      if (binLvL < 3) {
         //binning level too low, there would be less than 1 record per bin
         return docs;
      }
      if (!numDocs) {
         return null;
      }
      
      //set the first value of 'binId' and start an empty document.
      thisBinId = prevBinId = docs[0]._id - (docs[0]._id % binWidth); 

      for (doc_i = 0, bin_i = 0; doc_i < numDocs; doc_i++) {
         record = {
            ephm0: +docs[doc_i].ephm0,
            ephm1: +docs[doc_i].ephm1,
            ephm2: +docs[doc_i].ephm2,
            ephm3: +docs[doc_i].ephm3
         };

         thisBinId = docs[doc_i]._id - (docs[doc_i]._id % binWidth);
         if (thisBinId != prevBinId) {
            rebinned[bin_i] = {
               _id: prevBinId, gps: {}
            };
            rebinned[bin_i + 1] = {
               _id: prevBinId + (binWidth / 2), gps: {}
            };
            for (var_i in record) {
               rebinned[bin_i][var_i] = +loVal[var_i];
               rebinned[bin_i+ 1][var_i] = +hiVal[var_i];
            }

            loVal = {};
            hiVal = {};
            bin_i += 2;
            prevBinId = thisBinId;
         }
         
         for (var_i in record) {
            value = record[var_i];
            if (value || value === 0) {
               if (!(loVal[var_i] < value)) {
                  loVal[var_i] = value;
               };
               if (!(hiVal[var_i] > value)) {
                  hiVal[var_i] = value;
               };
            }
         }
      }
      
      rebinned[bin_i] = {
         _id: thisBinId, gps: {}
      };
      rebinned[bin_i + 1] = {
         _id: thisBinId + (binWidth / 2), gps: {}
      };
      for (var_i in record) {
         rebinned[bin_i][var_i] = +loVal[var_i];
         rebinned[bin_i+ 1][var_i] = +hiVal[var_i];
      }

      return rebinned;
   },
   misc : function(payload, docs, binLvL) {
      var
         numDocs = docs.length,
         binWidth = Math.pow(2, binLvL),
         prevFrame = NaN,
         loVal = NaN,
         hiVal = NaN,
         rebinned = [],
         doc_i, bin_i, thisBinId, prevBinId, value, fc;

      if (binLvL < 2) {
         //binning level too low, there would be less than 1 record per bin
         return docs;
      }
      if (!numDocs) {
         return null;
      }
      
      //set the first value of 'binId' and start an empty document.
      thisBinId = prevBinId = docs[0]._id - (docs[0]._id % binWidth); 
      prevFrame = +docs[0].fc;
      for (doc_i = 0, bin_i = 0; doc_i < numDocs; doc_i++) {
         thisBinId = docs[doc_i]._id - (docs[doc_i]._id % binWidth);
         if (thisBinId != prevBinId) {
            rebinned[bin_i] = {
               _id: prevBinId 
            };
            rebinned[bin_i + 1] = {
               _id: prevBinId + (binWidth / 2)
            };
            rebinned[bin_i].pps = +loVal;
            rebinned[bin_i + 1].pps = +hiVal;
            rebinned[bin_i].fc = prevFrame;
            rebinned[bin_i + 1].fc = +docs[doc_i].fc;

            loVal = NaN;
            hiVal = NaN;
            bin_i += 2;
            prevBinId = thisBinId;
         }
         
         value = +docs[doc_i].pps;
         if (value || value === 0) {
            if (!(loVal < value)) {
               loVal = value;
            };
            if (!(hiVal > value)) {
               hiVal = value;
            };
         }
      }
      
      rebinned[bin_i] = {
         _id: thisBinId
      };
      rebinned[bin_i + 1] = {
         _id: thisBinId + (binWidth / 2)
      };
      rebinned[bin_i].pps = +loVal;
      rebinned[bin_i + 1].pps = +hiVal;

      return rebinned;
   },
   magn : function(payload, docs, binLvL) {
      var
         numDocs = docs.length,
         binWidth = Math.pow(2, binLvL),
         record = {},
         loVal = {},
         hiVal = {},
         rebinned = [],
         var_i, doc_i, bin_i, thisBinId, prevBinId, value;

      if (!numDocs) {
         return null;
      }
      
      //set the first value of 'binId' and start an empty document.
      thisBinId = prevBinId = docs[0]._id - (docs[0]._id % binWidth); 
      prevFrame = +docs[0].fc;
      for (doc_i = 0, bin_i = 0; doc_i < numDocs; doc_i++) {
         thisBinId = docs[doc_i]._id - (docs[doc_i]._id % binWidth);
         
         record = {
            Bx:   +docs[doc_i].Bx,
            By:   +docs[doc_i].By,
            Bz:   +docs[doc_i].Bz,
            magB: +docs[doc_i].magB
         };
 
         if (thisBinId != prevBinId) {
            rebinned[bin_i] = {
               _id: prevBinId 
            };
            rebinned[bin_i + 1] = {
               _id: prevBinId + (binWidth / 2)
            };
            for (var_i in record) {
               rebinned[bin_i][var_i] = +loVal[var_i];
               rebinned[bin_i + 1][var_i] = +hiVal[var_i];
            }

            loVal = {};
            hiVal = {};
            bin_i += 2;
            prevBinId = thisBinId;
         }
         
         for (var_i in record) {
            value = record[var_i];
            if (value || value === 0) {
               if (!(loVal[var_i] < value)) {
                  loVal[var_i] = value;
               };
               if (!(hiVal[var_i] > value)) {
                  hiVal[var_i] = value;
               };
            }
         }
      }
      
      rebinned[bin_i] = {
         _id: thisBinId
      };
      rebinned[bin_i + 1] = {
         _id: thisBinId + (binWidth / 2)
      };
      for (var_i in record) {
         rebinned[bin_i][var_i] = +loVal[var_i];
         rebinned[bin_i + 1][var_i] = +hiVal[var_i];
      }

      return rebinned;
   },
   fspc : function(payload, docs, binLvL) {
      var
         numDocs = docs.length,
         binWidth = Math.pow(2, binLvL),
         record = {},
         loVal = {},
         hiVal = {},
         rebinned = [],
         var_i, doc_i, bin_i, thisBinId, prevBinId, value;

      if (!numDocs) {
         return null;
      }
      
      //set the first value of 'binId' and start an empty document.
      thisBinId = prevBinId = docs[0]._id - (docs[0]._id % binWidth); 
      prevFrame = +docs[0].fc;
      for (doc_i = 0, bin_i = 0; doc_i < numDocs; doc_i++) {
         thisBinId = docs[doc_i]._id - (docs[doc_i]._id % binWidth);
         
         record = {
            fspc1: +docs[doc_i].fspc1,
            fspc2: +docs[doc_i].fspc2,
            fspc3: +docs[doc_i].fspc3,
            fspc4: +docs[doc_i].fspc4
         };
 
         if (thisBinId != prevBinId) {
            rebinned[bin_i] = {
               _id: prevBinId 
            };
            rebinned[bin_i + 1] = {
               _id: prevBinId + (binWidth / 2)
            };
            for (var_i in record) {
               rebinned[bin_i][var_i] = +loVal[var_i];
               rebinned[bin_i + 1][var_i] = +hiVal[var_i];
            }

            loVal = {};
            hiVal = {};
            bin_i += 2;
            prevBinId = thisBinId;
         }
         
         for (var_i in record) {
            value = record[var_i];
            if (value || value === 0) {
               if (!(loVal[var_i] < value)) {
                  loVal[var_i] = value;
               };
               if (!(hiVal[var_i] > value)) {
                  hiVal[var_i] = value;
               };
            }
         }
   
         prevBinId = thisBinId;
      }
      
      rebinned[bin_i] = {
         _id: thisBinId
      };
      rebinned[bin_i + 1] = {
         _id: thisBinId + (binWidth / 2)
      };
      for (var_i in record) {
         rebinned[bin_i][var_i] = +loVal[var_i];
         rebinned[bin_i + 1][var_i] = +hiVal[var_i];
      }

      return rebinned;
   }
};

var j = schedule.scheduleJob('*/1 * * * *', function() {
   getLatestData();
});
   getLatestData();

