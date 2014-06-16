open Core.Std
open Async.Std

type s = { log : Zolog_std_event.t Zolog.t; konfig : Konfig.t }

module Flag = struct
  open Command.Spec

  let config_file () =
    flag "-c" ~doc:" Path to config file"
      (required string)
end

let logging = "logging"

let level_of_string = function
  | "debug"    -> Some Zolog_std_event.Log.Debug
  | "info"     -> Some Zolog_std_event.Log.Info
  | "warning"  -> Some Zolog_std_event.Log.Warning
  | "error"    -> Some Zolog_std_event.Log.Error
  | "critical" -> Some Zolog_std_event.Log.Critical
  | _          -> None

let create_console_handler konfig name =
  let read_options =
    let open Option.Monad_infix in
    Konfig.get [logging; name; "min_level"] konfig >>= fun min_level_s ->
    Konfig.get [logging; name; "max_level"] konfig >>= fun max_level_s ->
    level_of_string min_level_s                    >>= fun min_level ->
    level_of_string max_level_s                    >>= fun max_level ->
    Some (min_level, max_level)
  in
  match read_options with
    | Some (min_level, max_level) -> begin
      Zolog_std_event_console_backend.create
        (Zolog_std_event_writer_backend.default_formatter ~min_level ~max_level)
      >>= fun backend ->
      let handler = Zolog_std_event_console_backend.handler backend in
      Deferred.return (Some handler)
    end
    | None ->
      Deferred.return None

let create_file_handler konfig name =
  let read_options =
    let open Option.Monad_infix in
    Konfig.get [logging; name; "min_level"] konfig >>= fun min_level_s ->
    Konfig.get [logging; name; "max_level"] konfig >>= fun max_level_s ->
    Konfig.get [logging; name; "dir"] konfig       >>= fun dir ->
    level_of_string min_level_s                    >>= fun min_level ->
    level_of_string max_level_s                    >>= fun max_level ->
    Some (min_level, max_level, dir)
  in
  match read_options with
    | Some (min_level, max_level, dir) -> begin
      Zolog_std_event_file_backend.create
        ~formatter:(Zolog_std_event_writer_backend.default_formatter ~min_level ~max_level)
        (Zolog_std_event_file_backend.default_filename ~dir:dir)
      >>= fun backend ->
      let handler = Zolog_std_event_file_backend.handler backend in
      Deferred.return (Some handler)
    end
    | None ->
      Deferred.return None


let create_handler konfig name =
  match Konfig.get [logging; name; "type"] konfig with
    | Some "console" -> create_console_handler konfig name
    | Some "file"    -> create_file_handler konfig name
    | Some _         -> Deferred.return None
    | None           -> Deferred.return None

let create_handlers konfig =
  match Konfig.get [logging; "loggers"] konfig with
    | Some loggers_raw -> begin
      let loggers =
        List.filter
          ~f:(fun s -> not (String.is_empty s))
          (String.split ~on:' ' loggers_raw)
      in
      Deferred.List.map
        ~f:(create_handler konfig)
        loggers
      >>= fun maybe_handlers ->
      match Option.all maybe_handlers with
        | Some handlers ->
          Deferred.return handlers
        | None ->
          (* TODO: Make error handling better here *)
          failwith "Bad logger setup"
    end
    | None ->
      Deferred.return []


let start_log konfig =
  Zolog.start ()
  >>= fun logger ->
  create_handlers konfig
  >>= fun handlers ->
  Deferred.List.map ~f:(Zolog.add_handler logger) handlers
  >>= fun _ ->
  Deferred.return logger

let create_state config_file =
  let config = In_channel.read_all config_file in
  let konfig = Result.ok_or_failwith (Konfig.parse_string config) in
  start_log konfig
  >>= fun log ->
  Deferred.return { log; konfig }

let run_start config_file =
  create_state config_file
  >>= fun state ->
  Zolog_event.info
    ~n:["kaiju"; "main"; "started"]
    ~o:"kaiju_main"
    state.log
    "Kaiju started"
  >>= fun _ ->
  Zolog.sync state.log
  >>= fun _ ->
  Deferred.return (Ok (shutdown 0))

let start_cmd = Command.basic
  ~summary:"Start an instance"
  Command.Spec.(empty
                +> Flag.config_file ())
  (fun config_file () ->
    ignore (run_start config_file);
    never_returns (Scheduler.go ()))

let main () =
  Random.self_init ();
  Exn.handle_uncaught
    ~exit:true
    (fun () ->
      Command.run ~version:"1.0" ~build_info:"N/A"
        (Command.group ~summary:"kaiju commands"
           [ ("start", start_cmd) ]))

let () = main ()
