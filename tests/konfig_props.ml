open Core.Std

(* let ok_exn = function *)
(*   | Ok v    -> v *)
(*   | Error _ -> failwith "Error" *)

let parse_prop =
  QCheck.mk_test
    ~n:100
    ~name:"Parse"
    ~pp:QCheck.PP.(list (pair (list string) string))
    QCheck.Arbitrary.(list (pair (list string) string))
    (fun kvs ->
      let str =
        String.concat
          ~sep:"\n"
          (List.map
             ~f:(fun (k, v) ->
               String.concat ~sep:"." k ^ "=" ^ v)
             kvs)
      in
      Result.is_ok (Konfig.parse_string str))


let props =
  [ parse_prop
  ]

let _ =
  if QCheck.run_tests props then
    exit 0
  else
    exit 1
