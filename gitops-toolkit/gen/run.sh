pkl_k8s_version="1.1.1"

# Flux
# Helm Controller
# TODO: error in ChartSpec generation, most likely will be fixed in https://github.com/apple/pkl-pantry/pull/77
helm_controller_git_ref="v1.1.0"
pkl eval -p ref=$helm_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/helm-controller/HelmRelease.pkl -m io/fluxcd/toolkit/helm

# Image Automation Controller
image_automation_controller_git_ref="v0.39.0"
pkl eval -p ref=$image_automation_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/image-automation-controller/ImageUpdateAutomation.pkl -m io/fluxcd/toolkit/image

# Image Reflector Controller
image_reflector_controller_git_ref="v0.33.0"
pkl eval -p ref=$image_reflector_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/image-reflector-controller/ImagePolicy.pkl -m io/fluxcd/toolkit/image
pkl eval -p ref=$image_reflector_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/image-reflector-controller/ImageRepository.pkl -m io/fluxcd/toolkit/image

# Kustomize Controller
kustomize_controller_git_ref="v1.4.0"
pkl eval -p ref=$kustomize_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/kustomize-controller/Kustomization.pkl -m io/fluxcd/toolkit/kustomize

# Source Controller
source_controller_git_ref="v1.4.1"
pkl eval -p ref=$source_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/source-controller/Bucket.pkl -m io/fluxcd/toolkit/source
pkl eval -p ref=$source_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/source-controller/GitRepository.pkl -m io/fluxcd/toolkit/source
pkl eval -p ref=$source_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/source-controller/HelmChart.pkl -m io/fluxcd/toolkit/source
pkl eval -p ref=$source_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/source-controller/HelmRepository.pkl -m io/fluxcd/toolkit/source
pkl eval -p ref=$source_controller_git_ref -p pkl-k8s-version=$pkl_k8s_version configs/flux/source-controller/OCIRepository.pkl -m io/fluxcd/toolkit/source
