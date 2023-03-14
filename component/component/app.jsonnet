local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.openshift4_service_mesh;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('openshift4-service-mesh', params.namespace);

{
  'openshift4-service-mesh': app,
}
