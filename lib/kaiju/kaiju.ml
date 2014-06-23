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
  | "debug"    -> Ok Zolog_std_event.Log.Debug
  | "info"     -> Ok Zolog_std_event.Log.Info
  | "warning"  -> Ok Zolog_std_event.Log.Warning
  | "error"    -> Ok Zolog_std_event.Log.Error
  | "critical" -> Ok Zolog_std_event.Log.Critical
  | l          -> Error (`Invalid_log_level l)

let create_console_handler konfig name =
  let read_options =
    let open Result.Monad_infix in
    Konfig.get [logging; name; "min_level"] konfig >>= fun min_level_s ->
    Konfig.get [logging; name; "max_level"] konfig >>= fun max_level_s ->
    level_of_string min_level_s                    >>= fun min_level ->
    level_of_string max_level_s                    >>= fun max_level ->
    Ok (min_level, max_level)
  in
  Deferred.return read_options
  >>=? fun (min_level, max_level) ->
  Zolog_std_event_console_backend.create
    (Zolog_std_event_writer_backend.default_formatter ~min_level ~max_level)
  >>= fun backend ->
  let handler = Zolog_std_event_console_backend.handler backend in
  Deferred.return (Ok handler)

let create_file_handler konfig name =
  let read_options =
    let open Result.Monad_infix in
    Konfig.get [logging; name; "min_level"] konfig >>= fun min_level_s ->
    Konfig.get [logging; name; "max_level"] konfig >>= fun max_level_s ->
    Konfig.get [logging; name; "dir"] konfig       >>= fun dir ->
    level_of_string min_level_s                    >>= fun min_level ->
    level_of_string max_level_s                    >>= fun max_level ->
    Ok (min_level, max_level, dir)
  in
  Deferred.return read_options
  >>=? fun (min_level, max_level, dir) ->
  Zolog_std_event_file_backend.create
    ~formatter:(Zolog_std_event_writer_backend.default_formatter ~min_level ~max_level)
    (Zolog_std_event_file_backend.default_filename ~dir:dir)
  >>= fun backend ->
  let handler = Zolog_std_event_file_backend.handler backend in
  Deferred.return (Ok handler)

let create_handler konfig name =
  match Konfig.get [logging; name; "type"] konfig with
    | Ok "console" -> create_console_handler konfig name
    | Ok "file"    -> create_file_handler konfig name
    | Ok ht        -> Deferred.return (Error (`Invalid_handler_type ht))
    | Error _      -> Deferred.return (Error (`Missing_handler_type name))

let create_handlers konfig =
  Deferred.return (Konfig.get [logging; "names"] konfig)
  >>=? fun loggers_raw ->
  let loggers =
    List.filter
      ~f:(fun s -> not (String.is_empty s))
      (String.split ~on:' ' loggers_raw)
  in
  Deferred.List.map
    ~f:(create_handler konfig)
    loggers
  >>= fun maybe_handlers ->
  Deferred.return (Result.all maybe_handlers)

let start_log konfig =
  Zolog.start ()
  >>= fun logger ->
  create_handlers konfig
  >>=? fun handlers ->
  Deferred.List.map ~f:(Zolog.add_handler logger) handlers
  >>= fun _ ->
  Deferred.return (Ok logger)

let print_message_and_exit err =
  let string_of_error = function
    | `Not_found k ->
      sprintf
        "Config key not found: %s"
        (String.concat ~sep:"." k)
    | `Invalid_handler_type t ->
      sprintf
        "Invalid handle type: %s"
        t
    | `Invalid_log_level l ->
      sprintf
        "Invalid log level: %s"
        l
    | `Missing_handler_type n ->
      sprintf
        "Missing log handler type for logger: %s"
        n
    | `Parse_error l ->
      sprintf
        "Parse error in config file on line: %s"
        l
  in
  printf "Failed to initialize:\n%s\n%!" (string_of_error err);
  Deferred.return (shutdown 1)

let create_state config_file =
  let config = In_channel.read_all config_file in
  Deferred.return (Konfig.parse_string config)
  >>=? fun konfig ->
  start_log konfig
  >>=? fun log ->
  Deferred.return (Ok {log; konfig})

let started state =
  Zolog_event.info
    ~n:["kaiju"; "main"; "started"]
    ~o:"kaiju_main"
    state.log
    "Kaiju started"
  >>= fun _ ->
  Zolog.sync state.log
  >>= fun _ ->
  Deferred.return (shutdown 0)

let run_start config_file =
  create_state config_file
  >>= function
    | Ok state ->
      started state
    | Error err ->
      print_message_and_exit err

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
