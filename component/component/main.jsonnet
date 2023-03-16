// main template for openshift4-service-mesh
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.openshift4_service_mesh;

local needs_es_operator =
  local logging_params = std.get(inv.parameters, 'openshift4_logging', {
    components: {
      elasticsearch: {
        // if `openshift4_logging` key not in parameters, we always need to
        // install es operator.
        enabled: false,
      },
    },
  });
  !logging_params.components.elasticsearch.enabled;

local es_operator_ns = '%s-es-operator' % params.namespace;

local operatorlib = import 'lib/openshift4-operators.libsonnet';

// Define outputs below
{
  namespace: kube.Namespace(params.namespace) {
    metadata+: {
      annotations+: {
        // allow istio cni pods to be scheduled on all nodes.
        // TODO(sg): might be nicer to have a tighter node selector, but
        // removing the annotation completely to restrict the operator to app
        // nodes changes the daemonset behavior and messes up pod scheduling.
        'openshift.io/node-selector': '',
      },
      labels+: {
        // include namespace in cluster monitoring
        'openshift.io/cluster-monitoring': 'true',
        // ignore namespace in user-workload monitoring
        'openshift.io/user-monitoring': 'false',
      },
    },
  },
  [if needs_es_operator then 'es_operator']: [
    kube.Namespace(es_operator_ns) {
      metadata+: {
        annotations+: {
          'openshift.io/node-selector': 'node-role.kubernetes.io/infra=',
        },
        labels+: {
          // include namespace in cluster monitoring
          'openshift.io/cluster-monitoring': 'true',
        },
      },
    },
    operatorlib.OperatorGroup(es_operator_ns) {
      metadata+: {
        namespace: es_operator_ns,
      },
    },
    operatorlib.namespacedSubscription(
      es_operator_ns,
      'elasticsearch-operator',
      params.es_operator.channel,
      source='redhat-operators',
      installPlanApproval=params.es_operator.installPlanApproval,
    ),
  ],
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
