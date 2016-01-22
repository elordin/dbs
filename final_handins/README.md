# Wahlinformations-System
### Study project for the databases Lecture at TU Munich as part of the Software Engineering Masters program.

## Installation

### Database

`setup/database` contains shell and SQL scripts to create and populate the database.

Use postgres version 9.4 or above.

The following scripts are available:
- __runscripts_basic:__ initializes the database, schema etc. and populates the data of 2013
- __runscripts_all_archive2009_actual2013:__ as above, but also sets 2013 as the current election and populates 2009s archives.

Use `runscripts_all_archive2009_actual2013` for the complete setup.

### Web Server

The `setup/node` directory contains the full [node web server](https://nodejs.org/).

Install dependencies using `npm` from within that directory.

```
npm install
```

## Generator

Voting is only possible if Wahlbezirke exist.
They can be generated using the Stimmzettel-generator which creates them alongside the Stimmzettel, CitizenRegistrations etc.

The generator uses the [Scala programming language](http://scala-lang.org).

Using [sbt](http://www.scala-sbt.org) you can run it from the sbt shell using:

```
runMain Wahlinfo.Generator [year [wahlkreis-id]]
```

where `year` is the election year you want to create Stimmzettel for and
`wahlkreis-id` can either be a single id of the Wahlkreis or a range such as `15-42`.

Omitting the `wahlkreis-id`

## Benchmarking

The benchmarking client allows to specify URLs, a number of Clients and a frequency at which the clients send requests to the URLs and a probability with which the URLs are selected.

In `application.conf` e.g.:

```
benchmark {
    n = 10,
    t = "100 millis",
    deadline = "30 seconds"
    queries = [
        {
            name: "Q1"
            uri: "http://localhost:3000/q1",
            propability: 0.25
        }
    ]
}

```

where `n` is the number of clients,

`t` is the average time between requests,

`deadline` is the total runtime of the benchmarking process

and `queries` is a list of queries


Like the generator it uses Scala. Run it using sbt with
```
sbt run
```
