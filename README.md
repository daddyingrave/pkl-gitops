# GitOps Repository Pkl POC

In essence, this is just my lab work on the topic of how to make Gitops
using [Pkl](https://pkl-lang.org/) - a configuration language from Apple. Why? - I got
tired of Kustomize and Helm.

Pkl's developers have provided some [examples](https://github.com/apple/pkl-k8s-examples) of Pkl
usage for rendering Kubernetes manifests. These examples are based on their approach called
AppEnvCluster. This can be used (and extended) as a library
from [pkl-pantry](https://github.com/apple/pkl-pantry/tree/main/packages/k8s.contrib.appEnvCluster).
This approach is interesting, at least as a demonstration of how Pkl can be applied to Kubernetes
configuration.

However, I want to consider a case where base application manifests are described elsewhere (or at
least separately) and supplied to the GitOps repository as OCI artifacts, then further deployed
using Flux custom resources like Kustomization or HelmRelease.

## Requirements to consider

- Good tooling support:
    - Helm and Kustomize are generally good tools, but for large-scale GitOps repositories, they can
      be a nightmare to use.
    - I need features like auto-completion, inspections, automatic refactoring, and other similar
      features available in general-purpose programming languages, along with modern IDEs.
- Code generation:
    - It should be easy to generate code based on CRD, JSON Spec, or other YAML formats.
- Extension possibilities:
    - Libraries/Frameworks
    - Plugins
    - Distribution via a package management system
- Configuration must be separated by layers to fulfill the "DRY" principle:
    - Zero - defaults
    - First - `tiers` like test/stage/production
    - Second - `clusters`
    - Third - `namespaces`
    - Additionally, I should be able to introduce other logical layers like `environment` or
      `shard` (for example, for Flux scaling) as needed.
- Auto-calculations:
    - Ideally, most of the application configuration should be derivable from the current context.
    - Some variables could be calculated based on other variables.
- Interoperability with raw YAML:
    - SOPS secrets:
        - Read encoded secrets from a YAML file and modify them programmatically.
    - Flux Image Update Automation controller:
        - Read artifact tags from a YAML file updated by Flux.

Here's an improved version of your text with better grammar:

## Repository Structure

### [gitops-toolkit](gitops-toolkit)

This is supposed to be a separate external package. However, due to a
Pkl [limitation](https://github.com/apple/pkl/issues/483) (or maybe my own lack of understanding),
it's nearly impossible to use the package externally without publication.

The [gen](gitops-toolkit/gen) directory contains configuration and Pkl files generated based on the
configuration from CRDs.

The [src](gitops-toolkit/src) directory contains the source code for my little GitOps "framework" :)

I don't intend to make it look perfect; it's just a POC.

### [manifests/definitions](manifests)

The `manifests/definitions` directory is intended as a place for GitOps apps and any related
resources definitions.

To define a GitOps application class,
the [Kustomization.pkl](gitops-toolkit/src/apps/Kustomization.pkl)
or [HelmRelease.pkl](gitops-toolkit/src/apps/HelmRelease.pkl) modules are supposed to be extended.

For every GitOps application, a `Values` class must be created. This class should contain the app's
configuration. In the case of `HelmRelease`, its structure should match the values file structure.
For `Kustomize`, the approach could be more creative - we can either generate a `ConfigMap` with a
configuration file of any format (common renderers are supposed to be provided by the "framework"),
or we can map the `Values` class to environment variables and convert it to a `Kustomize` patch
which will be applied by Flux.

This part definitely needs a lot of improvement because the current approach is quite fragile.

The main reason we need a unique `Values` class per app is the autocompletion capabilities of Pkl.
It's really awesome to always know the possible config values for any application.

It's supposed that developers responsible for the application will document their `Values` class
extensively (ha ha).

### [manifests/clusters](manifests/clusters)

The heart of the GitOps repository. It is a representation of the expected state of all clusters
that are deployed from a given GitOps repository.

#### Clusters hierarchy

```
clusters
├── root.pkl
└── test
    ├── _patches
    │   ├── ...
    │   └── Redis.pkl
    ├── kitty-cluster
    │   ├── _patches
    │   │   ├── ...
    │   │   └── Redis.pkl
    │   ├── cluster.pkl
    │   ├── flux-system
    │   │   ├── namespace.pkl
    │   │   └── output.pkl
    │   └── paws-namespace
    │       ├── _patches
    │       │   ├── ...
    │       │   └── Redis.pkl
    │       ├── namespace.pkl
    │       ├── output.pkl
    │       ├── secrets
    │       │   └── postgres-db-credentials.yaml
    │       └── versions.yaml
    └── tier.pkl
```

#### 0 Layer - Clusters Directory Itself

At this layer, in [root.pkl](manifests/clusters/root.pkl), we extend
the [GitOpsTemplate.pkl](gitops-toolkit/src/GitOpsTemplate.pkl) module and define all the GitOps
applications that could be deployed in the repository. Due to the laziness of Pkl evaluations and
the ability to set rendering `output` explicitly, nothing will be evaluated and rendered here.

Subsequent modules
must [amend](https://pkl-lang.org/main/current/language-reference/index.html#module-amend) this one.
Thanks to the `amending` feature of Pkl, it will restrict the expansion of all child modules and
will only allow overriding values straightforwardly.

#### 1 Layer - Tier Level

[tier.pkl](manifests/clusters/test/tier.pkl) amends `root.pkl` and contains overrides for values
specific to the given tier.

Overrides can be introduced directly or by using the tier
level [_patches](manifests/clusters/test/_patches) directory.

Why have a `_patches` directory? When we have a GitOps repository managing dozens or even hundreds
of different applications, it becomes quite unmaintainable to describe all the overrides in a single
file. In the `_patches` directory, we can handle it on a per-app basis.

For a huge number of apps, even the current structure should be improved, but due to Pkl's
capabilities, this can be achieved quite easily.

#### 2 Layer - Cluster Level

[cluster.pkl](manifests/clusters/test/kitty-cluster/cluster.pkl) amends `tier.pkl` and works in the
same way but on one level deeper.

Cluster level overrides are a good place to define cross-namespace dependencies. For example, any
`HelmRelease` based application has a required `helmRepository` parameter, and only one
`helmRepository` should be deployed in the cluster. In our case, we will deploy it into the
`flux-system` namespace, but all the applications will be deployed to other namespaces. So, we can
define all the cross-references in the cluster level overrides and make these dependencies very
transparent.

#### 3 Layer - Namespace Level

[namespace.pkl](manifests/clusters/test/kitty-cluster/paws-namespace/namespace.pkl) amends
`cluster.pkl` and works in the same way but on one more level deeper.

Namespace level overrides are suitable for defining cross-application dependencies or for manifests
which, for some reason, should be deployed separately from the application manifests, like SOPS
encoded secrets (Flux restriction).

#### And Finally, a Place Where Magic Happens

[output.pkl](manifests/clusters/test/kitty-cluster/paws-namespace/output.pkl) amends
`namespace.pkl`, but it isn't responsible for configuration. Technically, overrides could also be
defined there, but this is not encouraged.

This place is responsible for forming the rendering output of the namespace. Also, Flux automation
could be enabled here, which is technically a configuration, but I think I'll find another way to
enable it in `namespace.pkl`.

I would like to point out separately that there is one more file at the namespace
level - [versions.yaml](manifests/clusters/test/kitty-cluster/paws-namespace/versions.yaml). The
justification for this is the necessity to use tools
like [Flux Image Automation Controller](https://fluxcd.io/flux/components/image/imageupdateautomations/),
and at the moment, it can only update image tags in YAML files. However, Pkl does a great job here,
and working with external YAML is quite pleasant.

## Variables Evaluation Order

(lowest priority) `defaults` -> `tier` -> `cluster` -> `namespace` (highest priority)

Values from a lower level override values from a higher level. Namespace overrides cluster, cluster
overrides tier, tier overrides defaults. It's pretty simple.

However, there is one exception: `_patches` are implemented using
Pkl's [mixins](https://pkl-lang.org/main/current/language-reference/index.html#mixins) and applied
just before rendering. This means that when evaluation for `_patches` starts, all inline patches
have already been evaluated.

This leads to the following evaluation order:

```
-> defaults 
  -> inline tier 
    -> inline cluster 
      -> inline namespace 
        -> tier patches 
          -> cluster patches 
            -> namespace patches
```

In other words, inline overrides are calculated first, followed by patches, both in the same order.

Here's an improved version of your text with better grammar:

## Rendering Output

For now, in this POC, I'm using PKL's Gradle plugin for rendering. File names and paths are
generated within the "framework." In the future, a more advanced solution will be required.

What I expect from a production-like rendering pipeline for a PKL-based GitOps repository:

- **Speed**: GitOps repositories in my organization are described in Kustomize, and
  `kustomize build` can take up to 1-2 minutes for a **single** cluster. This is incredibly slow.
  Ideally, YAML for all clusters should be rendered in 30 seconds or less.
- **Organized Output**: The rendering output must include organized `kustomization.yaml` files for
  each cluster and namespace level. This will allow Flux to sync the cluster state from a single
  directory.
- **Custom Readers**: PKL's custom readers may need to be implemented. In some cases, variables need
  to be resolved in an external system.
