package benchmark

import akka.actor.{Actor, ActorRef, Props, Terminated, PoisonPill}
import akka.event.Logging

import scala.concurrent.duration.{Duration, Deadline}


object AggregationActor {
    case class Success(query:Query, responseTime:Long)

    case class Failure(error:String)

    def props(deadline:Deadline, n:Int, t:Duration, queries:List[Query]):Props =
        Props(new AggregationActor(deadline, n, t, queries))
}

class AggregationActor(
    deadline: Deadline,
    n: Int,
    t: Duration,
    queries: List[Query]
) extends Actor {
    import AggregationActor._
    import Reaper._

    val logging = Logging(context.system, this)

    var responses:Map[Query, List[Long]] = Map[Query, List[Long]]()
    var failures:Int = 0

    val reaper = context.actorOf(Props[TerminationReaper], "reaper")

    for (i <- 1 to n) {
        context.actorOf(HttpRequester.props(deadline, reaper, t, queries), "requester" + i)
    }


    def receive = {
        case watchme:WatchMe =>
            reaper forward watchme
        case Success(query, responseTime) =>
            val current = responses.getOrElse(query, Nil)
            responses += (query -> (responseTime :: current))
        case Failure(error) =>
            failures = failures + 1
        case _ => logging.error("Received unknown message.")
    }


    def printAvgs:Unit = {
        val avgs = responses.mapValues( ds => (ds.length, ds.sum / ds.length) )
        avgs.map( (kvp:(Query, (Int, Long))) => println ( kvp._1 + ";" + kvp._2._1 + ";" + kvp._2._2 ) )
        println("")
    }


    override def postStop = {
        println("\n\nResults from " + responses.values.map(_.length).sum + " Requests\n")
        printAvgs
        println("Failures: " + failures + "\n")
    }

}
