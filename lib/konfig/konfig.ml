open Core.Std

module Konfig_map = Map.Make(struct
  type t = string list with compare,sexp
end)

type t = string Konfig_map.t

exception Parse_failure of string

let parse_line (header, konfig) = function
  | line when String.is_empty line ->
    (* Skip if empty *)
    (header, konfig)
  | line when line.[0] = '#' ->
    (* Skip if a comment *)
    (header, konfig)
  | line when line.[0] = '[' && line.[String.length line - 1] = ']' ->
    let header =
      String.split
        ~on:'.'
        (String.slice line 1 (String.length line - 1))
    in
    (header, konfig)
  | line when line.[0] = '[' ->
    raise (Parse_failure line)
  | line -> begin
    match String.lsplit2 ~on:'=' line with
      | Some (k, v) ->
        let full_key = header @ String.split ~on:'.' k in
        (header, Map.add ~key:full_key ~data:v konfig)
      | None ->
        raise (Parse_failure line)
  end

let parse_string str =
  let lines = List.map ~f:String.strip (String.split_lines str) in
  let konfig = Konfig_map.empty in
  try
    let (_, konfig) =
      List.fold_left
        ~f:parse_line
        ~init:([], konfig)
        lines
    in
    Ok konfig
  with
    | Parse_failure line ->
      Error (`Parse_error line)

let get k t =
  match Konfig_map.find t k with
    | Some v -> Ok v
    | None   -> Error (`Not_found k)

let to_list = Konfig_map.to_alist
