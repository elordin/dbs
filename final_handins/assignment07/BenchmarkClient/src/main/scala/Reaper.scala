package benchmark

import akka.actor.{Actor, ActorRef, Terminated}
import scala.collection.mutable.ArrayBuffer


object Reaper {
    // Used by others to register an Actor for watching
    case class WatchMe(ref: ActorRef)
}


abstract class Reaper extends Actor {
    import Reaper._

    val watched = ArrayBuffer.empty[ActorRef]

    def allSoulsReaped(): Unit

    final def receive = {
        case WatchMe(ref) =>
            context.watch(ref)
            watched += ref
        case Terminated(ref) =>
            watched -= ref
            if (watched.isEmpty) allSoulsReaped()
    }
}


class TerminationReaper extends Reaper {
    import context._

    def allSoulsReaped(): Unit = {
        context.system.terminate
    }
}
