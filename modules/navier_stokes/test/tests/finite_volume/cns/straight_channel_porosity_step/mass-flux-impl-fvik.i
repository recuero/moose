# Establish initial conditions based on STP
rho_initial=1.2754
p_initial=1.01e5
gamma=1.4
e_initial=${fparse p_initial / (gamma - 1) / rho_initial}
# No bulk velocity in the domain initially
et_initial=${e_initial}
rho_et_initial=${fparse rho_initial * et_initial}
# prescribe inlet rho = initial rho
rho_in=${rho_initial}
# u refers to the superficial velocity
u_in=1
# rho_u_in=${fparse rho_in * u_in} # Useful for Dirichlet
mass_flux_in=${fparse u_in * rho_in}
eps_in=1
real_u_in=${fparse u_in / eps_in}
# prescribe inlet pressure = initial pressure
p_in=${p_initial}
rho_u_in=${fparse rho_in * u_in} # Useful for Dirichlet
momentum_flux_in=${fparse eps_in * p_in + u_in * rho_in * u_in / eps_in}
# prescribe inlet e = initial e
et_in=${fparse e_initial + 0.5 * real_u_in * real_u_in}
# rho_et_in=${fparse rho_in * et_in} # Useful for Dirichlet
ht_in=${fparse et_in + p_in / rho_in}
enthalpy_flux_in=${fparse u_in * rho_in * ht_in}

# Uncomment this to do a safety check and make sure that you haven't accidentally forgotten to supply a defaulted parameter
# Default parameters can yield unanticipated results
[GlobalParams]
  vel = 'nonsense'
  advected_interp_method = 'nonsense'
  flux_interp_method = 'average'
  interp_method = 'average'
  momentum_component = 'nonsense'
  advected_quantity = 'nonsense'
  fp = fp
[]

[Mesh]
  [cartesian]
    type = GeneratedMeshGenerator
    dim = 1
    xmin = 0
    xmax = 15
    nx = 3
  []
  [middle]
    input = cartesian
    type = SubdomainBoundingBoxGenerator
    bottom_left = '5 0 0'
    top_right = '10 1 1'
    block_id = 1
  []
  [constant_again_porosity]
    input = middle
    type = SubdomainBoundingBoxGenerator
    bottom_left = '10 0 0'
    top_right = '15 1 1'
    block_id = 2
  []
[]

[Modules]
  [FluidProperties]
    [fp]
      type = IdealGasFluidProperties
    []
  []
[]

[Problem]
  kernel_coverage_check = false
[]

[Variables]
  [rho]
    type = MooseVariableFVReal
    initial_condition = ${rho_initial}
  []
  [rho_u]
    type = MooseVariableFVReal
    # initial_condition = 1e-15
    initial_condition = ${rho_u_in}
  []
  [rho_et]
      type = MooseVariableFVReal
    initial_condition = ${rho_et_initial}
  []
[]

[AuxVariables]
  [specific_volume]
    type = MooseVariableFVReal
  []
  [vel_x]
    type = MooseVariableFVReal
  []
  [porosity]
    type = MooseVariableFVReal
  []
  [real_vel_x]
    type = MooseVariableFVReal
  []
  [specific_internal_energy]
    type = MooseVariableFVReal
  []
  [pressure]
    type = MooseVariableFVReal
  []
  [mach]
    type = MooseVariableFVReal
  []
  [mass_flux]
    type = MooseVariableFVReal
  []
  [momentum_flux]
    type = MooseVariableFVReal
  []
  [enthalpy_flux]
    type = MooseVariableFVReal
  []
[]

[AuxKernels]
  [specific_volume]
    type = SpecificVolumeAux
    variable = specific_volume
    rho = rho
    execute_on = 'timestep_end'
  []
  [vel_x]
    type = NSVelocityAux
    variable = vel_x
    rho = rho
    momentum = rho_u
    execute_on = 'timestep_end'
  []
  [porosity]
    type = MaterialRealAux
    variable = porosity
    property = porosity
    execute_on = 'timestep_end'
  []
  [real_vel_x]
    type = ParsedAux
    variable = real_vel_x
    function = 'vel_x / porosity'
    args = 'vel_x porosity'
    execute_on = 'timestep_end'
  []
  [specific_internal_energy]
    type = ParsedAux
    variable = specific_internal_energy
    function = 'rho_et / rho - (real_vel_x * real_vel_x) / 2'
    args = 'rho_et rho real_vel_x'
    execute_on = 'timestep_end'
  []
  [pressure]
    type = NSPressureAux
    variable = pressure
    specific_volume = specific_volume
    e = specific_internal_energy
    fluid_properties = fp
    execute_on = 'timestep_end'
  []
  [mach]
    type = NSMachAux
    variable = mach
    vel_x = real_vel_x
    e = specific_internal_energy
    specific_volume = specific_volume
    execute_on = 'timestep_end'
    fluid_properties = 'fp'
  []
  [mass_flux]
    type = ParsedAux
    variable = mass_flux
    function = 'rho_u'
    args = 'rho_u'
    execute_on = 'timestep_end'
  []
  [momentum_flux]
    type = ParsedAux
    variable = momentum_flux
    function = 'vel_x * rho_u / porosity + pressure * porosity'
    args = 'vel_x rho_u porosity pressure'
    execute_on = 'timestep_end'
  []
  [enthalpy_flux]
    type = ParsedAux
    variable = enthalpy_flux
    function = 'vel_x * (rho_et + pressure)'
    args = 'vel_x rho_et pressure'
    execute_on = 'timestep_end'
  []
[]

[FVKernels]
  # [mass_time]
  #   type = FVPorosityTimeDerivative
  #   variable = rho
  # []
  [mass_advection]
    type = NSFVMassFluxAdvection
    variable = rho
    advected_quantity = 1
  []

  # [momentum_time]
  #   type = FVTimeKernel
  #   variable = rho_u
  # []
  [momentum_advection]
    type = NSFVMassFluxAdvection
    variable = rho_u
    advected_quantity = 'vel_x'
  []
  [momentum_pressure]
    type = PNSFVMomentumPressure
    variable = rho_u
    momentum_component = 'x'
  []
  [eps_grad]
    type = PNSFVPGradEpsilon
    variable = rho_u
    momentum_component = 'x'
    epsilon_function = 'epsilon_function'
  []

  # [energy_time]
  #   type = FVPorosityTimeDerivative
  #   variable = rho_et
  # []
  [energy_advection]
    type = NSFVMassFluxAdvection
    variable = rho_et
    advected_quantity = 'ht'
  []
[]

# [FVInterfaceKernels]
#   [eps_jump]
#     type = FVEpsilonJumps
#     variable1 = 'rho_u'
#     boundary = 'interface'
#     subdomain1 = '0'
#     subdomain2 = '1'
#     momentum_component = 'x'
#   []
# []

[FVBCs]
  [rho_left]
    type = FVNeumannBC
    boundary = 'left'
    variable = rho
    value = ${mass_flux_in}
  []
  [rho_right]
    type = NSFVMassFluxAdvectionBC
    boundary = 'right'
    variable = rho
    advected_quantity = 1
  []
  [rho_u_left]
    type = FVDirichletBC
    boundary = 'left'
    variable = rho_u
    value = ${mass_flux_in}
  []
  [rho_u_right]
    type = NSFVMassFluxAdvectionBC
    boundary = 'right'
    variable = rho_u
    advected_quantity = 'vel_x'
  []
  [rho_u_pressure_right]
    type = PNSFVMomentumSpecifiedPressureBC
    boundary = 'right'
    variable = rho_u
    momentum_component = 'x'
    pressure = ${p_initial}
  []
  [rho_et_left]
    type = PNSFVFluidEnergySpecifiedTemperatureBC
    variable = rho_et
    boundary = 'left'
    superficial_rhou = ${mass_flux_in}
    temperature = 273.15
  []
  [rho_et_right]
    type = NSFVMassFluxAdvectionBC
    boundary = 'right'
    variable = rho_et
    advected_quantity = 'ht'
  []
[]

[Functions]
  [epsilon_function]
    type = ParsedFunction
    value = 'if(x < 5, 1, if(x < 10, 1 - .1 * (x - 5), .5))'
  []
[]

[Materials]
  [var_mat]
    type = PorousConservedVarMaterial
    rho = rho
    rho_et = rho_et
    superficial_rhou = rho_u
    fp = fp
    porosity = porosity
  []
  [porosity]
    type = GenericFunctionMaterial
    prop_names = 'porosity'
    prop_values = 'epsilon_function'
  []
[]

[Executioner]
  solve_type = NEWTON
  nl_rel_tol = 1e-8
  type = Steady
  # nl_abs_tol = 1e-7
  # type = Transient
  # num_steps = 1000
  # [TimeStepper]
  #   type = IterationAdaptiveDT
  #   dt = 1e-4
  #   optimal_iterations = 6
  # []
  # steady_state_detection = true
  line_search = 'bt'
  automatic_scaling = true
  compute_scaling_once = false
  verbose = true
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'lu       mumps'
  nl_max_its = 10
[]

[Outputs]
  [out]
    type = Exodus
    execute_on = 'initial timestep_end'
  []
  checkpoint = true
[]

[Debug]
  show_var_residual_norms = true
[]
