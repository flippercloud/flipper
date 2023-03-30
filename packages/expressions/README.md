# Flipper Expressions

> A schema for Flipper Expressions

```
 PASS  test/schemas.test.js
  expressions.schema.json
    expressions
      valid
        ✓ "string" (2 ms)
        ✓ true
        ✓ false (1 ms)
        ✓ 1
        ✓ 1.1
      invalid
        ✓ null
        ✓ {}
        ✓ []
    Time
      valid
        ✓ {"Number":{"Time":["2021-01-01T00:00:00Z"]}} (1 ms)
        ✓ {"Number":{"Time":"2021-01-01T00:00:00-05:00"}} (1 ms)
        ✓ {"Number":{"Time":{"Property":"created_at"}}}
      invalid
        ✓ {"Time":"2021-01-01"} (1 ms)
        ✓ {"Time":"January 1, 2021 10:00"}
        ✓ {"Time":null}
        ✓ {"Time":false} (1 ms)
        ✓ {"Time":[{"Property":"created_at"},{"Property":"updated_at"}]}
    String
      valid
        ✓ {"String":true}
        ✓ {"String":false}
        ✓ {"String":"already a string"}
        ✓ {"String":1} (1 ms)
        ✓ {"String":1.1}
        ✓ {"String":[true]}
        ✓ {"String":[false]}
        ✓ {"String":["already a string"]}
        ✓ {"String":[1]}
        ✓ {"String":[1.1]}
        ✓ {"String":{"All":[]}}
        ✓ {"String":[{"Any":[]}]}
      invalid
        ✓ {"String":null}
        ✓ {"String":[true,false]}
        ✓ {"String":true,"Any":[]}
    Random
      valid
        ✓ {"Random":[]}
        ✓ {"Random":2}
        ✓ {"Random":[100]}
        ✓ {"Random":[{"Property":"max_rand"}]} (1 ms)
      invalid
        ✓ {"Random":null}
        ✓ {"Random":[1,2]}
    Property
      valid
        ✓ {"Property":"name"}
        ✓ {"Property":["flipper_id"]}
        ✓ {"Property":["flipper_id"]}
        ✓ {"Property":["flipper_id"]}
      invalid
        ✓ {"Property":[]}
        ✓ {"Property":null}
    PercentageOfActors
      valid
        ✓ {"PercentageOfActors":["User;1",42]} (1 ms)
        ✓ {"PercentageOfActors":["User;1",0]}
        ✓ {"PercentageOfActors":["string",99.99]}
        ✓ {"PercentageOfActors":["string",100]}
        ✓ {"PercentageOfActors":[{"Property":["flipper_id"]},{"Property":["probability"]}]}
        ✓ {"PercentageOfActors":["User;1",70]}
        ✓ {"PercentageOfActors":["User;1",70]}
        ✓ {"PercentageOfActors":["string",-1]}
        ✓ {"PercentageOfActors":["string",101]}
      invalid
        ✓ {"PercentageOfActors":["string"]}
        ✓ {"PercentageOfActors":[100]}
        ✓ {"PercentageOfActors":[{"Property":["flipper_id"]}]} (1 ms)
    Percentage
      valid
        ✓ {"Percentage":[0]}
        ✓ {"Percentage":[99.999]}
        ✓ {"Percentage":[100]}
        ✓ {"Percentage":[{"Property":["nines"]}]}
        ✓ {"Percentage":[-1]}
        ✓ {"Percentage":[101]} (1 ms)
      invalid
        ✓ {"Percentage":[1,2]}
        ✓ {"Percentage":[null]}
        ✓ {"Percentage":null}
    Number
      valid
        ✓ {"Number":0}
        ✓ {"Number":1}
        ✓ {"Number":1} (1 ms)
        ✓ {"Number":"0"}
        ✓ {"Number":"1"}
        ✓ {"Number":"1.0"}
        ✓ {"Number":[0]}
        ✓ {"Number":[1]}
        ✓ {"Number":[1]}
        ✓ {"Number":{"Property":"age"}}
      invalid
        ✓ {"Number":null}
        ✓ {"Number":[true,false]}
        ✓ {"Number":true,"Any":[]}
    Now
      valid
        ✓ {"Now":[]}
        ✓ {"String":{"Now":[]}}
      invalid
        ✓ {"Now":null}
        ✓ {"Now":[1]} (2 ms)
        ✓ {"Now":1}
    NotEqual
      valid
        ✓ {"NotEqual":[1,1]} (1 ms)
        ✓ {"NotEqual":["a","a"]}
        ✓ {"NotEqual":[1,2]}
        ✓ {"NotEqual":["a","b"]}
        ✓ {"NotEqual":[true,false]}
        ✓ {"NotEqual":[true,true]} (1 ms)
        ✓ {"NotEqual":[{"Property":"age"},21]}
      invalid
        ✓ {"NotEqual":[1,2,3]}
        ✓ {"NotEqual":[1]}
        ✓ {"NotEqual":1}
        ✓ {"NotEqual":null}
        ✓ {"NotEqual":[1,2],"Any":[]}
    LessThanOrEqualTo
      valid
        ✓ {"LessThanOrEqualTo":[1,1]}
        ✓ {"LessThanOrEqualTo":[2,1]}
        ✓ {"LessThanOrEqualTo":["a","b"]} (1 ms)
        ✓ {"LessThanOrEqualTo":["b","b"]}
        ✓ {"LessThanOrEqualTo":[1,2]}
        ✓ {"LessThanOrEqualTo":["b","a"]}
        ✓ {"LessThanOrEqualTo":[{"Property":"age"},21]}
        ✓ {"LessThanOrEqualTo":[{"Property":"age"},18]}
      invalid
        ✓ {"LessThanOrEqualTo":[1,2,3]}
        ✓ {"LessThanOrEqualTo":[1]}
        ✓ {"LessThanOrEqualTo":1}
        ✓ {"LessThanOrEqualTo":null}
        ✓ {"LessThanOrEqualTo":[1,2],"Any":[]}
    LessThan
      valid
        ✓ {"LessThan":[1,1]}
        ✓ {"LessThan":["a","a"]}
        ✓ {"LessThan":[2,1]}
        ✓ {"LessThan":[1,2]}
        ✓ {"LessThan":["b","a"]}
        ✓ {"LessThan":["a","b"]}
        ✓ {"LessThan":[{"Property":"age"},18]}
        ✓ {"LessThan":[{"Property":"age"},18]}
      invalid
        ✓ {"LessThan":[1,2,3]}
        ✓ {"LessThan":[1]}
        ✓ {"LessThan":1}
        ✓ {"LessThan":null} (1 ms)
        ✓ {"LessThan":[1,2],"Any":[]}
    GreaterThanOrEqualTo
      valid
        ✓ {"GreaterThanOrEqualTo":[1,1]}
        ✓ {"GreaterThanOrEqualTo":[2,1]}
        ✓ {"GreaterThanOrEqualTo":["a","b"]}
        ✓ {"GreaterThanOrEqualTo":["b","b"]}
        ✓ {"GreaterThanOrEqualTo":[1,2]}
        ✓ {"GreaterThanOrEqualTo":["b","a"]}
        ✓ {"GreaterThanOrEqualTo":["a","b"]}
        ✓ {"GreaterThanOrEqualTo":[true,false]}
        ✓ {"GreaterThanOrEqualTo":[{"Property":"age"},18]}
      invalid
        ✓ {"GreaterThanOrEqualTo":[1,2,3]}
        ✓ {"GreaterThanOrEqualTo":[1]}
        ✓ {"GreaterThanOrEqualTo":1}
        ✓ {"GreaterThanOrEqualTo":null}
        ✓ {"GreaterThanOrEqualTo":[1,2],"Any":[]}
    GreaterThan
      valid
        ✓ {"GreaterThan":[1,1]}
        ✓ {"GreaterThan":["a","a"]}
        ✓ {"GreaterThan":[2,1]}
        ✓ {"GreaterThan":["b","a"]}
        ✓ {"GreaterThan":["a","b"]}
        ✓ {"GreaterThan":[{"Property":"age"},18]}
      invalid
        ✓ {"GreaterThan":[1,2,3]}
        ✓ {"GreaterThan":[1]}
        ✓ {"GreaterThan":1}
        ✓ {"GreaterThan":null}
        ✓ {"GreaterThan":[1,2],"Any":[]}
    Equal
      valid
        ✓ {"Equal":[1,1]}
        ✓ {"Equal":["a","a"]}
        ✓ {"Equal":[1,2]}
        ✓ {"Equal":["a","b"]}
        ✓ {"Equal":[true,false]}
        ✓ {"Equal":[{"Property":"age"},21]}
      invalid
        ✓ {"Equal":[1,2,3]} (1 ms)
        ✓ {"Equal":[1]}
        ✓ {"Equal":1}
        ✓ {"Equal":null}
        ✓ {"Equal":[1,2],"Any":[]}
    Durations
      valid
        ✓ {"Duration":[2,"seconds"]} (1 ms)
        ✓ {"Duration":[2,"minutes"]}
        ✓ {"Duration":[2,"hours"]}
        ✓ {"Duration":[2,"days"]}
        ✓ {"Duration":[2,"weeks"]}
        ✓ {"Duration":[2,"months"]} (1 ms)
        ✓ {"Duration":[2,"years"]}
      invalid
        ✓ {"Duration":2}
        ✓ {"Duration":[2]}
        ✓ {"Duration":[4,"score"]}
    Boolean
      valid
        ✓ {"Boolean":true}
        ✓ {"Boolean":"true"}
        ✓ {"Boolean":1}
        ✓ {"Boolean":[true]}
        ✓ {"Boolean":["true"]}
        ✓ {"Boolean":[1]}
        ✓ {"Boolean":{"All":[]}}
        ✓ {"Boolean":false}
        ✓ {"Boolean":"false"}
        ✓ {"Boolean":0}
        ✓ {"Boolean":[false]}
        ✓ {"Boolean":["false"]}
        ✓ {"Boolean":[0]}
        ✓ {"Boolean":[{"Any":[]}]}
      invalid
        ✓ {"Boolean":null}
        ✓ {"Boolean":[true,false]}
        ✓ {"Boolean":true,"Any":[]}
    Any
      valid
        ✓ {"Any":[]} (1 ms)
        ✓ {"Any":[true]}
        ✓ {"Any":[true,false]}
        ✓ {"Any":[false,false]}
        ✓ {"Any":[1,true,"string"]}
        ✓ {"Any":true} (1 ms)
        ✓ {"Any":false}
        ✓ {"Any":[{"Boolean":false},{"Property":"admin"}]}
      invalid
        ✓ {"Any":null}
        ✓ {"Any":[],"All":[]}
    All
      valid
        ✓ {"All":[]}
        ✓ {"All":[true]}
        ✓ {"All":[true,false]}
        ✓ {"All":[1,true,"string"]}
        ✓ {"All":true}
        ✓ {"All":false}
        ✓ {"All":[{"Boolean":true},{"Property":"admin"}]}
      invalid
        ✓ {"All":null}
        ✓ {"All":[],"Any":[]}
❯```
