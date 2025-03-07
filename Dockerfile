FROM conda/miniconda3:latest

# Update conda
RUN conda update -n base -c defaults conda

# Add conda channels and set priority
RUN conda config --add channels bioconda
RUN conda config --add channels conda-forge
RUN conda config --set channel_priority strict

# Init conda for bash
RUN conda init bash 

# Copy files into image
COPY . /blast2tree/

# Create conda Blast2Tree enviroment
RUN conda env create -f blast2tree/blast2tree_environment.yml

# Add main script to path
ENV PATH="$PATH:/blast2tree/"

# Add execute permission 
RUN chmod +x /blast2tree/blast2tree.sh

# Command to make container stay running
CMD ["bin/bash"]
