(************************************************************
 *
 *                       IMITATOR
 *
 * Laboratoire Spécification et Vérification (ENS Cachan & CNRS, France)
 * LIPN, Université Paris 13, Sorbonne Paris Cité (France)
 *
 * Module description: Convert an input IMITATOR file to a file readable by HyTech
 *
 * Remark            : extensively copied from ModelPrinter as IMITATOR and HyTech syntax are very similar
 *
 * File contributors : Étienne André, Jaime Arias
 * Created           : 2016/01/26
 * Last modified     : 2019/05/16
 *
 ************************************************************)

open OCamlUtilities
open ImitatorUtilities
open Result
open AbstractModel




(************************************************************)
(** Header *)
(************************************************************)

(* Add a header to the model *)
let string_of_header model =
	let options = Input.get_options () in
	          "--************************************************************"
	^ "\n" ^ " -- File automatically generated by " ^ Constants.program_name ^ ""
	^ "\n" ^ " -- Version  : " ^ (ImitatorUtilities.program_name_and_version_and_nickname_and_build())
	^ "\n" ^ " -- Git      : " ^ (ImitatorUtilities.git_branch_and_hash)
	^ "\n" ^ " -- Model    : '" ^ options#model_input_file_name ^ "'"
	^ "\n" ^ " -- Generated: " ^ (now()) ^ ""
	^ "\n" ^ " -- Created to be compatible with 'hytech-v1.04f-Linux_static'"
	^ "\n" ^ " --************************************************************"



(************************************************************)
(** Footer *)
(************************************************************)

(* End of the file *)
let footer = "\n"
	^ "\n" ^ "--************************************************************"
	^ "\n" ^ "--* The end"
	^ "\n" ^ "--************************************************************"
(* 	^ "\n" ^ "end" *)
	^ "\n" ^ ""


(************************************************************)
(** Variable declarations *)
(************************************************************)

(* Convert a var_type into a string *)
let string_of_var_type = function
	| Var_type_clock -> "clock"
	| Var_type_discrete -> "discrete"
	| Var_type_parameter -> "parameter"


(* Collect all clocks that may be stopped in some location *)
(*** NOTE: this could be done once for all and stored in the model ***)
let find_stopwatches () =
	(* Retrieve the model *)
	let model = Input.get_model () in

	(* Print some information *)
	print_message Verbose_low "Computing the set of stopwatches.";

	(*** BADPROG ***)
	let list_of_stopwatches = ref [] in

	(*** WARNING: Do not look in the observer! ***)
	let pta_without_obs = List.filter (fun automaton_index -> not (model.is_observer automaton_index)) model.automata
	in

	(* Iterate on each automaton *)
	List.iter (fun automaton_index ->
		let locations = model.locations_per_automaton automaton_index in

		print_message Verbose_high ("Gathering stopwatches in automaton '" ^ (model.automata_names automaton_index)  ^ "'...");

		(* Iterate on each location *)
		List.iter (fun location_index ->
			print_message Verbose_high ("  Gathering stopwatches in location '" ^ (model.location_names automaton_index location_index)  ^ 	"'...");
			let stopwatches = model.stopwatches automaton_index location_index in
			(* Add to list *)
			list_of_stopwatches := List.rev_append !list_of_stopwatches stopwatches;
		) locations; (* end for each location *)
	) pta_without_obs; (* end for each PTA *)

	(* Print some information *)
	print_message Verbose_medium "Set of stopwatches successfully computed.";

	(* Return only one each variable *)
	list_only_once !list_of_stopwatches


(* Convert the initial variable declarations into a string *)
let string_of_declarations model stopwatches clocks =
	let string_of_variables list_of_variables =
		string_of_list_of_string_with_sep ", " (List.map model.variable_names list_of_variables) in

		"var "
	^
	(if clocks <> [] then
		("\n\t" ^ (string_of_variables clocks) ^ "\n\t\t: clock;\n") else "")
	^
	(if stopwatches <> [] then
		("\n\t" ^ (string_of_variables stopwatches) ^ "\n\t\t: stopwatch;\n") else "")
	^
	(if model.nb_discrete > 0 then
		("\n\t" ^ (string_of_variables model.discrete) ^ "\n\t\t: discrete;\n") else "")
	^
	(if model.nb_parameters > 0 then
		("\n\t" ^ (string_of_variables model.parameters) ^ "\n\t\t: parameter;\n") else "")


(************************************************************)
(** Automata *)
(************************************************************)

(* Convert the synclabs of an automaton into a string *)
let string_of_synclabs model automaton_index =
	"synclabs: "
	^ (let synclabs, _ = (List.fold_left (fun (synclabs, first) action_index ->
		match model.action_types action_index with
		(* Case sync: declare *)
		| Action_type_sync ->
			synclabs
			^ (if not first then ", " else "")
			^ (model.action_names action_index)
			(* Not the first one anymore *)
			, false
		(* Case nosync: do not declare *)
		| Action_type_nosync -> (synclabs, first)
	) ("", true) (model.actions_per_automaton automaton_index)) in synclabs)
	^ ";"


(* Convert the initially of an automaton into a string *)
let string_of_initially model automaton_index =
	let inital_global_location  = model.initial_location in
	let initial_location = Location.get_location inital_global_location automaton_index in
	"initially "
	^ (model.location_names automaton_index initial_location)
	^ ";"


(* Convert the invariant of a location into a string *)
let string_of_invariant model automaton_index location_index stopwatches clocks =
	(* Invariant *)
	"while "
	^ (LinearConstraint.string_of_pxd_linear_constraint model.variable_names (model.invariants automaton_index location_index))

	(* Handle stopwatches *)
	^
	let stopped = model.stopwatches automaton_index location_index in
	let running = list_diff stopwatches stopped in

	let stopped_str = string_of_list_of_string_with_sep ","
		(List.map (fun clock_index ->
			" d" ^ (model.variable_names clock_index) ^ " = 0"
		) stopped
	) in

	(*** NOTE: it seems HyTech requests the rate of ALL stopwatches to be explicitly defined in all invariants... ***)
	let running_str = string_of_list_of_string_with_sep ","
		(List.map (fun clock_index ->
			" d" ^ (model.variable_names clock_index) ^ " = 1"
		) running
	) in

	(* Comma only if both lists are non empty *)
	let comma = if stopped <> [] && running <> [] then ", " else "" in

	" wait{" ^ stopped_str ^ comma ^ running_str ^ "}"


(* Convert a sync into a string *)
let string_of_sync model action_index =
	match model.action_types action_index with
	| Action_type_sync -> " sync " ^ (model.action_names action_index)
(* 	| Action_type_nosync -> " (* sync " ^ (model.action_names action_index) ^ "*) " *)
	| Action_type_nosync -> " "



let string_of_clock_updates model = function
	| No_update -> ""
	| Resets list_of_clocks ->
		string_of_list_of_string_with_sep ", " (List.map (fun variable_index ->
			(model.variable_names variable_index)
			^ "' = 0"
		) list_of_clocks)
	| Updates list_of_clocks_lt ->
		string_of_list_of_string_with_sep ", " (List.map (fun (variable_index, linear_term) ->
			(model.variable_names variable_index)
			^ "' = "
			^ (LinearConstraint.string_of_pxd_linear_term model.variable_names linear_term)
		) list_of_clocks_lt)



(* Convert a list of updates into a string *)
(*** WARNING: calling string_of_arithmetic_expression might yield a syntax incompatible with HyTech for models more expressive than its input syntax! ***)
(*** TODO: fix or print warning ***)
let string_of_discrete_updates model updates =
	string_of_list_of_string_with_sep ", " (List.map (fun (variable_index, arithmetic_expression) ->
		(* Convert the variable name *)
		(model.variable_names variable_index)
		^ "' = "
		(* Convert the arithmetic_expression *)
		^ (ModelPrinter.string_of_arithmetic_expression model.variable_names arithmetic_expression)
	) updates)


(* Convert a transition of a location into a string *)
(** NOTE: currently HyTech does not support conditional *)
let string_of_transition model automaton_index action_index (guard, updates, destination_location) =
	let clock_updates = updates.clock in
	let discrete_updates = updates.discrete in
	let conditional_updates = updates.conditional in
	(if conditional_updates <> [] then print_message Verbose_standard "Conditions are not supported by HyTech. Ignoring..." );
	"\n\t" ^ "when "
	(* Convert the guard *)
	^ (ModelPrinter.string_of_guard model.variable_names guard)

	(* Convert the updates *)
	^ " do {"
	(* Clock updates *)
	^ (string_of_clock_updates model clock_updates)
	(* Add a coma in case of both clocks and discrete *)
	^ (if clock_updates != No_update && discrete_updates != [] then ", " else "")
	(* Discrete updates *)
	^ (string_of_discrete_updates model discrete_updates)
	^ "} "

	(* Convert the sync *)
	^ (string_of_sync model action_index)
	(* Convert the destination location *)
	^ " goto " ^ (model.location_names automaton_index destination_location)
	^ ";"


(* Convert the transitions of a location into a string *)
let string_of_transitions model automaton_index location_index =
	string_of_list_of_string (
	(* For each action *)
	List.map (fun action_index ->
		(* Get the list of transitions *)
		let transitions = List.map model.transitions_description (model.transitions automaton_index location_index action_index) in
		(* Convert to string *)
		string_of_list_of_string (
			(* For each transition *)
			List.map (string_of_transition model automaton_index action_index) transitions
			)
		) (model.actions_per_location automaton_index location_index)
	)


(* Convert a location of an automaton into a string *)
let string_of_location model automaton_index location_index stopwatches clocks =
	"\n"
	^ (if model.is_urgent automaton_index location_index then "urgent loc " else "loc ")
	^ (model.location_names automaton_index location_index)
	^ (match model.costs automaton_index location_index with
		| None -> ""
		| Some cost -> "[" ^ (LinearConstraint.string_of_p_linear_term model.variable_names cost) ^ "]"
	)
	^ ": "
	^ (string_of_invariant model automaton_index location_index stopwatches clocks)
	^ (string_of_transitions model automaton_index location_index)


(* Convert the locations of an automaton into a string *)
let string_of_locations model automaton_index stopwatches clocks =
	string_of_list_of_string_with_sep "\n " (List.map (fun location_index ->
		string_of_location model automaton_index location_index stopwatches clocks
	) (model.locations_per_automaton automaton_index))


(* Convert an automaton into a string *)
let string_of_automaton model automaton_index stopwatches clocks =
	(* Print some information *)
	print_message Verbose_low ("Translating automaton '" ^ (model.automata_names automaton_index) ^ "'...");

	"\n--************************************************************"
	^ "\n automaton " ^ (model.automata_names automaton_index)
	^ "\n--************************************************************"
	^ "\n " ^ (string_of_synclabs model automaton_index)
	^ "\n " ^ (string_of_initially model automaton_index)
	^ "\n " ^ (string_of_locations model automaton_index stopwatches clocks)
	^ "\n end -- " ^ (model.automata_names automaton_index) ^ ""
	^ "\n--************************************************************"


(* Convert the automata into a string *)
let string_of_automata model stopwatches clocks =
	(*** WARNING: Do not print the observer ***)
	let pta_without_obs = List.filter (fun automaton_index -> not (model.is_observer automaton_index)) model.automata
	in
	(* Print all (other) PTA *)
	string_of_list_of_string_with_sep "\n\n" (
		List.map (fun automaton_index -> string_of_automaton model automaton_index stopwatches clocks
	) pta_without_obs)



(************************************************************)
(** Initial state *)
(************************************************************)
let string_of_initial_state () =
	(* Retrieve the model *)
	let model = Input.get_model () in

	(* Print some information *)
	print_message Verbose_low "Translating the initial state...";

	(* Header of initial state *)
	"\n"
	^ "\n" ^ "--************************************************************"
	^ "\n" ^ "-- Initial state"
	^ "\n" ^ "--************************************************************"
	^ "\n" ^ "var init : region;"
	^ "\n" ^ ""
	^ "\n" ^ "init := True"

	(* Initial location *)
	^ "\n" ^ "\t------------------------------------------------------------"
	^ "\n" ^ "\t-- Initial location"
	^ "\n" ^ "\t------------------------------------------------------------"
	^
	(*** WARNING: Do not print the observer ***)
	let pta_without_obs = List.filter (fun automaton_index -> not (model.is_observer automaton_index)) model.automata
	in

	(* Handle all (other) PTA *)
	let inital_global_location  = model.initial_location in
	let initial_automata = List.map
	(fun automaton_index ->
		(* Finding the initial location for this automaton *)
		let initial_location = Location.get_location inital_global_location automaton_index in
		(* '& loc[pta] = location' *)
		"\n\t& loc[" ^ (model.automata_names automaton_index) ^ "] = " ^ (model.location_names automaton_index initial_location)
	) pta_without_obs
	in string_of_list_of_string initial_automata

	(* Initial discrete assignments *)
	^ "\n" ^ ""
	^ "\n" ^ "\t------------------------------------------------------------"
	^ "\n" ^ "\t-- Initial discrete assignments "
	^ "\n" ^ "\t------------------------------------------------------------"
	^
	let initial_discrete = List.map
	(fun discrete_index ->
		(* Finding the initial value for this discrete *)
		let initial_value = Location.get_discrete_value inital_global_location discrete_index in
		(* '& var = val' *)
		"\n\t& " ^ (model.variable_names discrete_index) ^ " = " ^ (NumConst.string_of_numconst initial_value)
	) model.discrete
	in string_of_list_of_string initial_discrete

	(* Initial constraint *)
	^ "\n" ^ ""
	^ "\n" ^ "\t------------------------------------------------------------"
	^ "\n" ^ "\t-- Initial constraint"
	^ "\n" ^ "\t------------------------------------------------------------"
	^ "\n\t & " ^ (LinearConstraint.string_of_px_linear_constraint model.variable_names model.initial_constraint)

	(* Footer of initial state *)
	^ "\n" ^ ""
	^ "\n" ^ ";"



(************************************************************)
(** Property *)
(************************************************************)
let property_header =
	"\n"
	^ "\n" ^ "--************************************************************"
	^ "\n" ^ "--* Property specification "
	^ "\n" ^ "--************************************************************"
	^ "\n" ^ ""



let string_of_unreachable_location model unreachable_global_location =
	(* Convert locations *)
	string_of_list_of_string_with_sep " & " (List.map (fun (automaton_index, location_index) ->
			"loc[" ^ (model.automata_names automaton_index) ^ "]" ^ " = " ^ (model.location_names automaton_index location_index)
		) unreachable_global_location.unreachable_locations
	)
	^
	(* Separator *)
	(if unreachable_global_location.unreachable_locations <> [] && unreachable_global_location.discrete_constraints <> [] then " & " else "")
	^
	(* Convert discrete *)
	string_of_list_of_string_with_sep " & " (List.map (function
		| Discrete_l (discrete_index , discrete_value)
			-> (model.variable_names discrete_index) ^ " < " ^ (NumConst.string_of_numconst discrete_value)
		| Discrete_leq (discrete_index , discrete_value)
			-> (model.variable_names discrete_index) ^ " <= " ^ (NumConst.string_of_numconst discrete_value)
		| Discrete_equal (discrete_index , discrete_value)
			-> (model.variable_names discrete_index) ^ " = " ^ (NumConst.string_of_numconst discrete_value)
		| Discrete_neq (discrete_index , discrete_value)
			->
				print_warning "Inequality <> may be disallowed by HyTech";
				(model.variable_names discrete_index) ^ " <> " ^ (NumConst.string_of_numconst discrete_value)
		| Discrete_geq (discrete_index , discrete_value)
			-> (model.variable_names discrete_index) ^ " >= " ^ (NumConst.string_of_numconst discrete_value)
		| Discrete_g (discrete_index , discrete_value)
			-> (model.variable_names discrete_index) ^ " > " ^ (NumConst.string_of_numconst discrete_value)
		| Discrete_interval (discrete_index , min_discrete_value, max_discrete_value)
			-> (model.variable_names discrete_index) ^ " in [" ^ (NumConst.string_of_numconst min_discrete_value) ^ " , " ^ (NumConst.string_of_numconst max_discrete_value) ^ "]"
		) unreachable_global_location.discrete_constraints
	)


(** Convert the correctness property to a string *)
let string_of_property model property =
	match property with
	(* An "OR" list of global locations *)
	| Unreachable_locations unreachable_global_location_list ->
		"property := unreachable " ^ (
			string_of_list_of_string_with_sep "\n or \n " (List.map (string_of_unreachable_location model) unreachable_global_location_list)
		)

	(* if a2 then a1 has happened before *)
	| Action_precedence_acyclic (a1 , a2) ->
		"property := if " ^ (model.action_names a2) ^ " then " ^ (model.action_names a1) ^ " has happened before;"
	(* everytime a2 then a1 has happened before *)
	| Action_precedence_cyclic (a1 , a2) ->
		"property := everytime " ^ (model.action_names a2) ^ " then " ^ (model.action_names a1) ^ " has happened before;"
	(* everytime a2 then a1 has happened exactly once before *)
	| Action_precedence_cyclicstrict (a1 , a2) ->
		"property := everytime " ^ (model.action_names a2) ^ " then " ^ (model.action_names a1) ^ " has happened exactly once before;"

	(*** NOTE: not implemented ***)
(*	(* if a1 then eventually a2 *)
	| Eventual_response_acyclic (a1 , a2) -> ""
	(* everytime a1 then eventually a2 *)
	| Eventual_response_cyclic (a1 , a2) -> ""
	(* everytime a1 then eventually a2 once before next *)
	| Eventual_response_cyclicstrict (a1 , a2) -> ""
	*)

	(* a no later than d *)
	| Action_deadline (a, d) ->
		"property := " ^ (model.action_names a) ^ " no later than " ^ (LinearConstraint.string_of_p_linear_term model.variable_names d) ^ ";"

	(* if a2 then a1 happened within d before *)
	| TB_Action_precedence_acyclic (a1 , a2, d) ->
		"property := if " ^ (model.action_names a2) ^ " then " ^ (model.action_names a1) ^ " has happened within " ^ (LinearConstraint.string_of_p_linear_term model.variable_names d) ^ " before;"
	(* everytime a2 then a1 happened within d before *)
	| TB_Action_precedence_cyclic (a1 , a2, d) ->
		"property := everytime " ^ (model.action_names a2) ^ " then " ^ (model.action_names a1) ^ " has happened within " ^ (LinearConstraint.string_of_p_linear_term model.variable_names d) ^ " before;"
	(* everytime a2 then a1 happened once within d before *)
	| TB_Action_precedence_cyclicstrict (a1 , a2, d) ->
		"property := everytime " ^ (model.action_names a2) ^ " then " ^ (model.action_names a1) ^ " has happened once within " ^ (LinearConstraint.string_of_p_linear_term model.variable_names d) ^ " before;"

	(* if a1 then eventually a2 within d *)
	| TB_response_acyclic (a1 , a2, d) ->
		"property := if " ^ (model.action_names a2) ^ " then eventually " ^ (model.action_names a1) ^ " within " ^ (LinearConstraint.string_of_p_linear_term model.variable_names d) ^ ";"
	(* everytime a1 then eventually a2 within d *)
	| TB_response_cyclic (a1 , a2, d) ->
		"property := everytime " ^ (model.action_names a2) ^ " then eventually " ^ (model.action_names a1) ^ " within " ^ (LinearConstraint.string_of_p_linear_term model.variable_names d) ^ ";"
	(* everytime a1 then eventually a2 within d once before next *)
	| TB_response_cyclicstrict (a1 , a2, d) ->
		"property := if " ^ (model.action_names a2) ^ " then eventually " ^ (model.action_names a1) ^ " within " ^ (LinearConstraint.string_of_p_linear_term model.variable_names d) ^ " once before next;"

	(* sequence a1, ..., an *)
	| Sequence_acyclic action_index_list ->
		"property := sequence (" ^ (string_of_list_of_string_with_sep ", " (List.map model.action_names action_index_list)) ^ ");"
	(* always sequence a1, ..., an *)
	| Sequence_cyclic action_index_list ->
		"property := always sequence (" ^ (string_of_list_of_string_with_sep ", " (List.map model.action_names action_index_list)) ^ ");"

	(*** NOTE: Would be better to have an "option" type ***)
	| Noproperty -> "-- (no property)"



(** Convert the projection to a string *)
let string_of_projection model =
	match model.projection with
	| None -> ""
	| Some parameter_index_list ->
		"\n-- projectresult(" ^ (string_of_list_of_string_with_sep ", " (List.map model.variable_names parameter_index_list)) ^ "); (NOT CONSIDERED BY HyTech)"


(** Convert the optimization to a string *)
let string_of_optimization model =
	match model.optimized_parameter with
	| No_optimization -> ""
	| Minimize parameter_index ->
		"-- minimize(" ^ (model.variable_names parameter_index) ^ "); (NOT CONSIDERED BY HyTech)"
	| Maximize parameter_index ->
		"-- maximize(" ^ (model.variable_names parameter_index) ^ "); (NOT CONSIDERED BY HyTech)"



(************************************************************)
(** Model *)
(************************************************************)

(* Convert the model into a string *)
let string_of_model model =
	(* Compute stopwatches *)
	let stopwatches = find_stopwatches() in

	(* Partition between real clocks and stopwatches *)
	let stopwatches, clocks = List.partition (fun variable_index -> List.mem variable_index stopwatches) model.clocks_without_special_reset_clock in

	(* The header *)
	string_of_header model
	(* The variable declarations *)
	^  "\n" ^ string_of_declarations model stopwatches clocks

	(* All automata *)
	^  "\n" ^ string_of_automata model stopwatches clocks

	(* The initial state *)
	^ "\n" ^ string_of_initial_state ()

	(* The property *)
	(*** TODO: encode reachability properties! ***)
	^ property_header
	^  "\n" ^ "--" ^ string_of_property model model.user_property ^ " (NOT CONSIDERED BY HYTECH)"

	(* The projection *)
	^  "\n" ^ string_of_projection model

	(* The optimization *)
	^  "\n" ^ string_of_optimization model

	(* The footer *)
	^  "\n" ^ footer
