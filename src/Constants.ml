(************************************************************
 *
 *                       IMITATOR
 * 
 * Laboratoire Spécification et Vérification (ENS Cachan & CNRS, France)
 * LIPN, Université Paris 13, Sorbonne Paris Cité (France)
 * 
 * All (?) constants of IMITATOR
 * 
 * File contributors : Étienne André
 * Created           : 2014/10/24
 * Last modified     : 2018/04/06
 *
 ************************************************************)

 
(************************************************************)
(************************************************************)
(* IMITATOR NAME AND VERSION *)
(************************************************************)
(************************************************************)

let program_name = "IMITATOR"

let version_string = "2.10.2"

let version_name = "Butter Jellyfish"

(* Path ending with "/" *)
let path_to_program =
	(* Try to find the last occurrence of '/' in the string *)
	try(
		let full_path_to_binary = Sys.executable_name in
		let last_position = String.rindex full_path_to_binary '/' in
		(* Remove last element (program name) *)
		(String.sub full_path_to_binary 0 last_position)
		(* Add final "/" *)
		^ "/"
	) with Not_found ->
	(* If unexpected form, assume path is root *)
		"/"


(************************************************************)
(************************************************************)
(* External binaries *)
(************************************************************)
(************************************************************)

let dot_command = "dot"


(************************************************************)
(************************************************************)
(* FILE EXTENSIONS *)
(************************************************************)
(************************************************************)


(** Extension for input model files *)
let model_extension = ".imi"

(** Extension for files output *)
let result_file_extension = ".res"

let default_dot_image_extension = "jpg"
let dot_file_extension = "dot"
let states_file_extension = "states"
let cartography_extension = "png"


(************************************************************)
(************************************************************)
(* Hashtable initial size (just a guess) *)
(************************************************************)
(************************************************************)
let guessed_nb_states_for_hashtable = 100


(************************************************************)
(************************************************************)
(* Internal cuisine *)
(************************************************************)
(************************************************************)
(* Name of the special clock always reset (used for NZ model checking, and not to be printed in normal operations) *)
let special_reset_clock_name = "special_0_clock"
