# k8c-install-webinar

This repository will be used for hosting the script. It is used to generate 
couple of secrets and populate the installation files. 

## Script usage

In the installation files we need to specify values and options that are
required to successfully install Kubermatic. Those can be set manually or we can 
use this script to make it more user friendly.

Make the script executable:
```bash
chmod u+x generate.sh
```

Three mandatory flags needs to be set:
- folder: where the Kubermatic tarball has been extracted
- kubeconfig: Path to the kubeconfig file of the Seed cluster
- kubermatic-domain: Domain used to access Kubermatic

One optional flag, that is set by default to false:
- letsencrypt-prod: boolean saying which if a well-known certificate authority
will be signing the certificates.

We can now run the script:
```bash
./generate.sh --folder '.' --kubeconfig ./kubeconfig --kubermatic-domain kubermatic.test.com --letsecnrypt-prod y 
```

This will generate the files used for the installation in the root directory:
```bash
bash-5.0$ ls -l
-rw-r--r--   1 staff  staff  131673 Jul 20 14:02 CHANGELOG.md
-rw-r--r--   1 staff  staff   12608 Jul 20 14:02 LICENSE
drwxr-xr-x  15 staff  staff     480 Jul 27 22:12 charts
drwxr-xr-x   5 staff  staff     160 Jul 27 22:12 examples
-rwxr-xr-x   1 staff  staff    4838 Jul 29 13:27 generate.sh
-rw-r--r--   1 staff  staff    5490 Jul 29 13:27 kubeconfig
-rw-r--r--   1 staff  staff    1832 Jul 29 13:38 kubermatic.yaml
-rw-r--r--   1 staff  staff    8186 Jul 29 13:38 seed.yaml
-rw-r--r--   1 staff  staff    1799 Jul 29 13:38 values.yaml
```
