# Wahlinformations-System
### Study project for the databases Lecture at TU Munich as part of the Software Engineering Masters program.

## Installation

### Database

`scripts_to_create_DB` contains shell and SQL scripts to create and populate the database.

Use postgres version 9.4 or above.

The following scripts are available:
- _runscripts_basic:_
- _runscripts:_

### Web Server

The `node-server` directory contains the full (https://nodejs.org/)[node web server].

Install dependencies using `npm` from within that directory.

```
npm install
```

# Generator

Voting is only possible if Wahlbezirke exist.
They can be generated using the Stimmzettel-generator which creates them alongside the Stimmzettel, CitizenRegistrations etc.

The generator uses the (http://scala-lang.org)[Scala programming language].

Using (http://www.scala-sbt.org)[sbt] you can run it from the sbt shell using:

```
runMain Wahlinfo.Generator [year [wahlkreis-id]]
```

where `year` is the election year you want to create Stimmzettel for and
`wahlkreis-id` can either be a single id of the Wahlkreis or a range such as `15-42`.

