// main template for openshift4-service-mesh
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.openshift4_service_mesh;

local operatorlib = import 'lib/openshift4-operators.libsonnet';

// Define outputs below
{
  operator: [
    operatorlib.OperatorGroup(params.namespace),
    operatorlib.namespacedSubscription(
      params.namespace,
      'servicemeshoperator',
      params.operator.channel,
      'redhat-operators',
      installPlanApproval=params.operator.installPlanApproval,
    ),
  ],
}
