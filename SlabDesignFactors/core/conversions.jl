kgm3_to_kipin3(kgm3::Real) = kgm3 * 3.6125e-8

psf_to_ksi(psf::Real) = psf * 0.000006944444 # convert to ksi
plf_to_kpi(plf::Real) = (plf / (12 * 1000)) # convert to kip/in

convert_to_m = Dict(
    :m => 1.0,          # 1 meter is the standard
    :cm => 0.01,        # 1 centimeter = 0.01 meters
    :mm => 0.001,       # 1 millimeter = 0.001 meters
    :in => 0.0254,      # 1 inch = 0.0254 meters
    :ft => 0.3048       # 1 foot = 0.3048 meters
)
