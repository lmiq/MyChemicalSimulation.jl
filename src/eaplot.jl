"""
    create_piecewise_parabolas(y_values::NTuple{3, Real}, d_spacing::Real, x_center::Real)

Create a piecewise function composed of three parabolas.

The function is continuous and has a continuous first derivative (smooth).
The critical points of the parabolas are:
- P1: (x_center - d_spacing, y_values[1]) - Minima
- P2: (x_center, y_values[2])            - Maxima
- P3: (x_center + d_spacing, y_values[3]) - Minima

# Arguments
- `y_values::NTuple{3, Real}`: A tuple `(y1, y2, y3)` containing the y-coordinates of the critical points. 
                               `y2` must be greater than `y1` and `y3`.
- `d_spacing::Real`: The horizontal distance between adjacent critical points. Must be positive.
- `x_center::Real`: The x-coordinate of the critical point of the middle parabola.

# Returns
- A function `f(x::Real)::Real` which evaluates the piecewise parabolic function at `x`.

# Example
"""
function create_piecewise_parabolas(
    y_values::AbstractVector{<:Real}, d_spacing::Real, x_center::Real
)
    y1, y2, y3 = y_values

    if !(y2 > y1 && y2 > y3)
        error("The middle y-value (y_values[2]) must be greater than the other two (y_values[1], y_values[3]).")
    end
    if d_spacing <= 0
        error("Parameter d_spacing must be positive.")
    end
    
    # X-coordinates of critical points
    xc1 = x_center - d_spacing
    xc2 = x_center
    xc3 = x_center + d_spacing
    
    # Y-differences (positive values)
    Y1_val = y2 - y1 # Difference y2-y1
    Y3_val = y2 - y3 # Difference y2-y3
    
    # Determine x-coordinates of joining points (x_12 and x_23)
    # R1 = xc2 - x_12
    # L2 = x_23 - xc2
    # We choose R1 + L2 = d_spacing, and Y1_val * L2 = Y3_val * R1
    # This leads to:
    R1 = d_spacing * Y1_val / (Y1_val + Y3_val)
    L2 = d_spacing * Y3_val / (Y1_val + Y3_val)
    
    x_12 = xc2 - R1
    x_23 = xc2 + L2
    
    # Coefficients 'a' for parabola P(x) = a(x-h)^2 + k
    common_factor_for_a2 = (Y1_val + Y3_val) / (d_spacing^2)
    
    a1 = Y1_val * common_factor_for_a2 / Y3_val
    a2 = -common_factor_for_a2
    a3 = Y3_val * common_factor_for_a2 / Y1_val
    
    # The returned piecewise function
    function piecewise_function(x::Real)
        if x < x_12
            return a1 * (x - xc1)^2 + y1
        elseif x < x_23 # x_12 <= x < x_23
            return a2 * (x - xc2)^2 + y2
        else # x_23 <= x
            return a3 * (x - xc3)^2 + y3
        end
    end
    
    return piecewise_function

end
