#LABEL maintainer="Combiz Khozoie, Ph.D. c.khozoie@imperial.ac.uk, Alan Murphy, a.murphy@imperial.ac.uk"

## Use rstudio installs binaries from RStudio's RSPM service by default,
## Uses the latest stable ubuntu, R and Bioconductor versions. Created on unbuntu 20.04, R 4.3 and BiocManager 3.18
FROM rocker/r-ubuntu:22.04 AS base

## Re-enable apt cache to use cache mounts
RUN rm -f /etc/apt/apt.conf.d/docker-clean

## Add packages dependencies
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update \
	&& apt-get install -y --no-install-recommends apt-utils \
	&& apt-get install -y --no-install-recommends \
        cmake \
        gdal-bin \
        libcairo2-dev \
        libcurl4-openssl-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libfribidi-dev \
        libgdal-dev \
        libgeos-dev \
        libglpk-dev \
        libharfbuzz-dev \
        libhdf5-dev \
        libicu-dev \
        libpng-dev \
        libproj-dev \
        libsqlite3-dev \
        libssl-dev \
        libudunits2-dev \
        libxml2-dev \
        make \
        pandoc \ 
        patch \
        perl \
        python3 \
        zlib1g-dev \
        pip \
        curl \
        unzip \
        qpdf

RUN --mount=type=cache,target=/tmp/downloaded_packages \
install2.r -e -n -1 -s remotes
RUN --mount=type=cache,target=/tmp/downloaded_packages \
Rscript -e 'remotes::install_version("Matrix", version = "1.6-5", repos = "http://cran.r-project.org")'

RUN --mount=type=cache,target=/tmp/downloaded_packages \
install2.r -e -n -1 -s \
Matrix \
argparse \
assertthat \
BiocManager \
cli \
cowplot \
data.table \
devtools \
DirichletReg \
dplyr \
DT \
english \
enrichR \
forcats \
formattable \
future \
future.apply \
gdtools \
ggdendro \
ggplot2 \
ggpubr \
ggrepel \
ggridges \
Hmisc \
httr \
ids \
knitr \
leaflet \
magrittr \
lme4 \
igraph \
paletteer \
plyr \
prettydoc \
purrr \
qpdf \
qs \
R.utils \
RANN \
rcmdcheck \
Rcpp \
RcppArmadillo \
RcppEigen \
RcppParallel \
RcppProgress \
remotes \
rlang \
rmarkdown \
Rtsne \
scales \
sctransform \
Seurat \
SeuratObject \
snow \
spelling \
stringr \
testthat \
threejs \
tibble \
tidyr \
tidyselect \
tidyverse \
UpSetR \
utils \
vroom \
WebGestaltR

## Install Bioconductor packages
COPY ./misc/requirements-bioc.R .
RUN --mount=type=cache,target=/tmp/downloaded_packages \
Rscript -e 'requireNamespace("BiocManager"); BiocManager::install(ask=F);' \
&& Rscript requirements-bioc.R

## Install from GH the following
RUN --mount=type=cache,target=/tmp/downloaded_packages \
installGithub.r \
chris-mcginnis-ucsf/DoubletFinder \
ropensci/plotly \
cole-trapnell-lab/monocle3 \
theislab/kBET \
NathanSkene/EWCE \
jlmelville/uwot \
hhoeflin/hdf5r \
ropensci/bib2df \
cvarrichio/Matrix.utils

# install older version of rliger
RUN --mount=type=cache,target=/tmp/downloaded_packages \
Rscript -e 'remotes::install_version("rliger", version = "1.0.1", repos = "http://cran.r-project.org")'

## Install scFlow package
WORKDIR scFlow
# Run R CMD check, install package from source - will fail with any errors or warnings
RUN --mount=type=bind,target=.,source=. \
Rscript -e "devtools::check(vignettes = FALSE)"

RUN --mount=type=bind,target=.,source=. \
Rscript -e 'remotes::install_local(upgrade = "never")'

# -----------------------------------------------------------------------------

FROM base AS minified 

RUN Rscript -e ' remove.packages(c( \
"apcluster", \
"patchwork", \
"spelling", \
"BiocStyle"))'

RUN apt-get -y purge cmake make qpdf patch \
&& apt-get -y autoremove \
&& apt-get -y autoclean \
&& rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------

FROM scratch AS squash
COPY --from=minified / /
CMD ["bash"]

# -----------------------------------------------------------------------------

FROM base AS with_dev_tools

RUN wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2024.04.2-764-amd64.deb

RUN --mount=type=cache,target=/var/cache/apt \
apt install -y ./rstudio-server-2024.04.2-764-amd64.deb pip

RUN ln -fs /usr/lib/rstudio-server/bin/rstudio-server /usr/local/bin \
&& ln -fs /usr/lib/rstudio-server/bin/rserver /usr/local/bin \
&& echo "rsession-which-r=$(which R)" >/etc/rstudio/rserver.conf \
&& echo "lock-type=advisory" >/etc/rstudio/file-locks \
&& echo log-level=warn > /etc/rstudio/logging.conf \
&& echo logger-type=syslog >> /etc/rstudio/logging.conf

RUN --mount=type=cache,target=/root/.cache/pip \
pip install stratocumulus \
&& curl https://sdk.cloud.google.com > install.sh \
&& bash install.sh --disable-prompts \
&& curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
-o "awscliv2.zip" \
&& unzip awscliv2.zip \
&& ./aws/install \
&& rm -rf awscliv2.zip install.sh /tmp/*

EXPOSE 8787
RUN useradd rstudio -m \
&& adduser rstudio sudo \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers \
&& echo rstudio:password | chpasswd
CMD ["sh", "-c", "rstudio-server start & bash"]

