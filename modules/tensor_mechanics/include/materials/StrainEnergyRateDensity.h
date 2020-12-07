//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "Material.h"
#include "DerivativeMaterialInterface.h"
#include "RankTwoTensorForward.h"
#include "RadialReturnCreepStressUpdateBase.h"
#include "ADRadialReturnCreepStressUpdateBase.h"
#include "MooseTypes.h"

// select the appropriate class based on the is_ad boolean parameter
template <bool is_ad>
using GenericRadialReturnCreepStressUpdateBase =
    typename std::conditional<is_ad,
                              ADRadialReturnCreepStressUpdateBase,
                              RadialReturnCreepStressUpdateBase>::type;

/**
 * StrainEnergyRateDensity calculates the strain energy rate density.
 */
template <bool is_ad>
class StrainEnergyRateDensityTempl : public DerivativeMaterialInterface<Material>
{
public:
  static InputParameters validParams();

  StrainEnergyRateDensityTempl(const InputParameters & parameters);

  virtual void initQpStatefulProperties() override;
  virtual void initialSetup() override;
  virtual void computeQpProperties() override;

private:
  /// Base name of the material system
  const std::string _base_name;

  /// The strain energy density material property
  MaterialProperty<Real> & _strain_energy_rate_density;

  /// The strain energy density material property from previous step
  const MaterialProperty<Real> & _strain_energy_rate_density_old;

  /// Current and old values of stress
  const GenericMaterialProperty<RankTwoTensor, is_ad> & _stress;

  /// Current value of the strain rate
  const GenericMaterialProperty<RankTwoTensor, is_ad> & _strain_rate;

  /// Older value of the strain rate
  const MaterialProperty<RankTwoTensor> & _strain_rate_old;

  /// number of plastic models
  const unsigned _num_models;

  /// The user supplied list of inelastic models to compute the strain energy release rate
  std::vector<GenericRadialReturnCreepStressUpdateBase<is_ad> *> _inelastic_models;

  /// Whether we compute the strain energy rate density numerically
  const bool _is_numerical;
};

typedef StrainEnergyRateDensityTempl<false> StrainEnergyRateDensity;
typedef StrainEnergyRateDensityTempl<true> ADStrainEnergyRateDensity;
