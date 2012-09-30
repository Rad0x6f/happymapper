## 0.5.5 / 2012-09-30

* Fix for Boolean attributes to ensure that they parse correctly (zrob)

## 0.5.4/ 2012-09-25

* #wrap method allows you to better model xml content that is buried deep
  within the xml. This implementation addresses issues with calling #to_xml
  with content that was parsed from an xpath. (zrob)

* Parent HappyMapper classes may dictate the name of the tag for the child
  HappyMapper instances. (zrob)

## 0.5.3/ 2012-09-23

* String is the default type for parsed fields. (crv)
* Update the attributes of an existing HappyMapper instance with new XML (benoist)