# Physical Constants
const GRAVITY = 9.80665 # N/kg

# Material Densities (kg/m³)
const ρ_CONCRETE = 2400.0
const ρ_STEEL = 7850.0
const ρ_REBAR = 7850.0

# Material Densities (kip/in³)
const ρ_CONCRETE_KIPIN3 = kgm3_to_kipin3(ρ_CONCRETE)
const ρ_STEEL_KIPIN3 = kgm3_to_kipin3(ρ_STEEL)
const ρ_REBAR_KIPIN3 = kgm3_to_kipin3(ρ_REBAR)

# Elasticity Coefficients
const ECC_STEEL = 1.22
const ECC_CONCRETE = 0.152
const ECC_REBAR = 0.854