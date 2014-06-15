open Core.Std
open Async.Std

type s = { log : Zolog_std_event.t Zolog.t }

let start_log () =
  Zolog.start ()
  >>= fun logger ->
  Zolog_std_event_console_backend.create
    Zolog_std_event_writer_backend.default_formatter
  >>= fun backend ->
  let handelr = Zolog_std_event_console_backend.handler backend in
  Zolog.add_handler logger handelr
  >>= fun _ ->
  Deferred.return logger

let create_state () =
  start_log ()
  >>= fun log ->
  Deferred.return { log }

let main () =
  create_state ()
  >>= fun state ->
  Zolog_event.info
    ~n:["kaiju"; "main"; "started"]
    ~o:"kaiju_main"
    state.log
    "Kaiju successfully started"
  >>= fun _ ->
  Zolog.sync state.log
  >>= fun _ ->
  Deferred.return (Ok (shutdown 0))

let () =
  ignore (main ());
  never_returns (Scheduler.go ())
