name := "BenchmarkClient"

version := "1.0"

scalaVersion := "2.11.7"

scalacOptions ++= Seq("-unchecked", "-deprecation", "-feature")

resolvers += "Big Bee Consultants" at "http://repo.bigbeeconsultants.co.uk/repo"

libraryDependencies ++= Seq(
    "com.typesafe.akka" %% "akka-actor" % "2.4.1",
    "org.skife.com.typesafe.config" % "typesafe-config" % "0.3.0",
    "io.spray"          %%  "spray-can" % "1.3.3"
)