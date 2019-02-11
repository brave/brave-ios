# Domain Parser 
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)


A full-swift simple library which allows to parse host to parse hostnames, and public suffix, using the [Public Suffix List](https://publicsuffix.org)

This Library allows to know which is the domain name for a given URL. 

## What is Public Suffix List ?

PSL list all the known public suffix  (like: com, co.uk, nt.edu.au, ...). 
Without this information we are not able to determine which part of a URL is the domain, Since a suffix can have more than one Label. 
The PSL includes ICANN (official top level domains) but also privates one (like us-east-1.amazonaws.com)

Examples: 

| URL                                     | Domain             |
|--------------------------------:|:-----------------:|
| sub.domain.co.uk               | domain.co.uk    |
| auth.impala.dashlane.com | dashlane.com    |


## Usage 

#### Initialization: 
```
import DomainParser
let domainParse = try DomainParser()
```

You should use the same instance when you parse multiple URLs.

``` 
let domain = domainParser.parse("awesome.dashlane.com").domain
print(domain) // dashlane.com
```


``` 
let suffix = domainParser.parse("awesome.dashlane.com").suffix
print(suffix) // com
let suffix = domainParser.parse("awesome.dashlane.co.uk").suffix
print(suffix) // co.uk
```

## Update the Public Suffist List 
In the `script` folder, run: 
``` 
swift UpdatePSL.swift 
```


