## Generator

Voting is only possible if Wahlbezirke exist.
They can be generated using the Stimmzettel-generator which creates them alongside the Stimmzettel, CitizenRegistrations etc.

The generator uses the (http://scala-lang.org)[Scala programming language].

Using (http://www.scala-sbt.org)[sbt] you can run it from the sbt shell using:

```
runMain Wahlinfo.Generator [year [wahlkreis-id]]
```

where `year` is the election year you want to create Stimmzettel for and
`wahlkreis-id` can either be a single id of the Wahlkreis or a range such as `15-42`.
