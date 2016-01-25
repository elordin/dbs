package benchmark

import akka.actor.ActorSystem

import scala.concurrent.duration._
import java.util.concurrent.TimeUnit

import com.typesafe.config.{Config, ConfigFactory}
import spray.http.IllegalUriException

import AggregationActor._

import scala.collection.JavaConverters

case class FailedResponse() extends Exception


object Client extends App {
    // args : Array[String]

    var config = ConfigFactory.load

    val system = ActorSystem("BenchmarkClient")

    val deadline:Deadline = try {
        val parsedDuration = Duration(config.getString("benchmark.deadline"))
        if (parsedDuration.isFinite)
            FiniteDuration(parsedDuration.toMillis, TimeUnit.MILLISECONDS).fromNow
        else
            throw new IllegalArgumentException
    } catch {
        case _:NumberFormatException =>
            println("Invalid format for deadline. Falling back to 30 seconds.")
            30.seconds.fromNow
    }

    val n:Int = try {
        config.getInt("benchmark.n")
    } catch {
        case _:Exception =>
            println("Invalid format for n. Falling back to 2.")
            2
    }

    val t:FiniteDuration = try {
        val parsedDuration = Duration(config.getString("benchmark.t"))
        if (parsedDuration.isFinite)
            FiniteDuration(parsedDuration.toMillis, TimeUnit.MILLISECONDS)
        else
            throw new IllegalArgumentException
    } catch {
        case _:Exception =>
            println("Invalid format for t. Falling back to 100 millis.")
            100.millis
    }

    val queries:List[Query] = try {
        val javaConfigList = config.getConfigList("benchmark.queries")
        var queryList:List[Query] = List[Query]()

        val scalaConfigList = JavaConverters.asScalaBufferConverter(javaConfigList).asScala
        scalaConfigList.map(
            (queryConfig:Config) => {
                try {
                    val name = queryConfig.getString("name")
                    val uri = queryConfig.getString("uri")
                    val propability = queryConfig.getInt("propability")
                    val query:Query = GenericQuery(name, uri, propability)
                    queryList ::= query
                } catch {
                    case e:IllegalUriException =>
                        println("Invalid URI format found in config. Ingoring.")
                }
            }
        )
        if (queryList.length < 1) {
            println("No valid queries found. Falling back to default.")
            throw new IllegalArgumentException
        } else {
            queryList
        }
    } catch {
        case _:Exception =>
            println("Invalid query format. Falling back to default.")
            List(Q1, Q2, Q3, Q4, Q5, Q6)
    }

    val aggregator = system.actorOf(AggregationActor.props( deadline, n, t, queries ), "aggregator")
}