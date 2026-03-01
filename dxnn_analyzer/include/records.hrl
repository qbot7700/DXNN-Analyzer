%% DXNN Agent Records - Copied from DXNN-Trader for compatibility

-record(sensor,{id,name,type,cx_id,scape,vl,fanout_ids=[],generation,format,parameters,gt_parameters,phys_rep,vis_rep,pre_f,post_f}). 
-record(actuator,{id,name,type,cx_id,scape,vl,fanin_ids=[],generation,format,parameters,gt_parameters,phys_rep,vis_rep,pre_f,post_f}).
-record(neuron, {id, generation, cx_id, af, pf, aggr_f, input_idps=[], input_idps_modulation=[], output_ids=[], ro_ids=[]}).
-record(cortex, {id, agent_id, neuron_ids=[], sensor_ids=[], actuator_ids=[]}).
-record(substrate, {id, agent_id, densities, linkform, plasticity=none, cpp_ids=[],cep_ids=[]}). 
-record(agent,{id, encoding_type, generation, population_id, specie_id, cx_id, fingerprint, constraint, evo_hist=[], fitness=0, innovation_factor=0, pattern=[], tuning_selection_f, annealing_parameter, tuning_duration_f, perturbation_range, mutation_operators,tot_topological_mutations_f,heredity_type,substrate_id}).
-record(specie,{id, population_id, fingerprint, constraint, agent_ids=[], dead_pool=[], champion_ids=[], fitness, innovation_factor={0,0},stats=[]}).
-record(trace,{stats=[],tot_evaluations=0,step_size=500}).
-record(population,{id, polis_id, specie_ids=[], morphologies=[], innovation_factor, evo_alg_f, fitness_postprocessor_f, selection_f, trace=#trace{}}).
-record(stat,{morphology,specie_id,avg_neurons,std_neurons,avg_fitness,std_fitness,max_fitness,min_fitness,avg_diversity,evaluations,time_stamp}).
-record(topology_summary,{type,tot_neurons,tot_n_ils,tot_n_ols,tot_n_ros,af_distribution}).

-record(constraint,{
	morphology,
	connection_architecture,
	neural_afs,
	neural_pfns,
	substrate_plasticities,
	substrate_linkforms,
	neural_aggr_fs,
	tuning_selection_fs,
	tuning_duration_f,
	annealing_parameters,
	perturbation_ranges,
	agent_encoding_types,
	heredity_types,
	mutation_operators,
	tot_topological_mutations_fs,
	population_evo_alg_f,
	population_fitness_postprocessor_f,
	population_selection_f
}).

-record(experiment,{
	id,
	backup_flag = true,
	pm_parameters,
	init_constraints,
	progress_flag=in_progress,
	trace_acc=[],
	run_index=1,
	tot_runs=10,
	run_configs=[],
	notes,
	started={date(),time()},
	completed,
	interruptions=[]
}).

-record(pmp,{
	op_mode=gt,
	population_id,
	survival_percentage=0.5,
	specie_size_limit=10,
	init_specie_size=10,
	polis_id = mathema,
	generation_limit = 100,
	evaluations_limit,
	fitness_goal = inf,
	benchmarker_pid
}).
