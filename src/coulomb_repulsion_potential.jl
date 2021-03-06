struct CoulombRepulsionPotential{PP<:AbstractPoissonProblem,
                                 Potential, Diag, Vec}
    poisson::PP
    V̂::Potential
    r⁻¹::Diag
    tmp::Vec
end

function CoulombRepulsionPotential(R::CompactBases.BasisOrRestricted,
                                   poisson::AbstractPoissonProblem;
                                   apply_metric_inverse=true)
    V̂ = DiagonalOperator(applied(*, R, poisson.Y))
    r = axes(R,1)
    r⁻¹ = R'*QuasiDiagonal(1 ./ r)*R
    tmp = zeros(eltype(poisson), size(R,2))
    CoulombRepulsionPotential(poisson, V̂, apply_metric_inverse ? LinearOperator(r⁻¹, R) : r⁻¹, tmp)
end

function CoulombRepulsionPotential(R::CompactBases.BasisOrRestricted,
                                   k::Number, ::Type{C}=eltype(R); apply_metric_inverse=true, kwargs...) where C
    poisson = PoissonProblem(R, k, C; kwargs...)
    CoulombRepulsionPotential(R, poisson, apply_metric_inverse=apply_metric_inverse)
end

function Base.copyto!(potential::CoulombRepulsionPotential, ρ::Density)
    solve!(potential.poisson, ρ)
    copyto!(potential.V̂, potential.poisson.Y)
    potential
end

LinearAlgebra.mul!(y, potential::CoulombRepulsionPotential, x, α::Number=true, β::Number=false) =
    mul!(y, potential.r⁻¹,
         mul!(potential.tmp, potential.V̂, x),
         α, β)

function Base.Matrix(potential::CoulombRepulsionPotential)
    V̂ = potential.V̂
    R = V̂.R
    r = axes(R, 1)
    Matrix(V̂, R \ inv.(r))
end

Base.iszero(::CoulombRepulsionPotential) = false

Base.show(io::IO, potential::CoulombRepulsionPotential) =
    write(io, "CoulombRepulsionPotential based on solving $(typeof(potential.poisson))")

export CoulombRepulsionPotential
