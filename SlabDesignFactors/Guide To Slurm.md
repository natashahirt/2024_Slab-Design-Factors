# Guide to accessing the cluster

## External links
https://github.com/jcwright77/engaging_cluster_howto
https://engaging-web.mit.edu/eofe-wiki/logging_in/

## Getting onto the cluster

You need to create an account on the engaging cluster by logging onto https://engaging-ood.mit.edu

This will give you access to the cluster. You access it through your computer terminal through one of four login nodes (eofe7, eofe8, eofe9, eofe10) by typing in:

ssh nhirt@eofe7.mit.edu

You may need to enter your kerb password. To expedite this process, set up an ssh key. eofe7 is recommended by ORCD because it has the most pre-installed software, but it is also somewhat out of date compared to the other nodes.

Do not attempt to use *sudo* in the terminal. You do not have root access.

## Connecting VSCode

You can connect to remote computing in VSCode using the little green >< at the bottom left of your window (it should be in the toolbar). Click on it, then press "Connect to Host". Select "Configure SSH Hosts" from the following menu and then open the config file that is provided as the first option. Enter:

    Host eofe7.mit.edu
    HostName eofe7.mit.edu
    User nhirt

    Host eofe-compute
    User nhirt
    HostName nodename
    ProxyJump eofe-login

    Host github.com
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_rsa

This will give you access to the remote hosts. If you have an ssh key set up, you won't have to use your password to log in. Else, type in your password.

## Installing julia

Julia may not be pre-installed; further, even if it is, you may want a specific version of julia to run on your node.

1. find the version of julia that you want to run from the julia kernel. Because a version like 2.46.0 is listed alphanumerically before 2.6.0, the version at the bottom of the page may not be the most recent. Make sure you find the most recent version before downloading.
   1. https://julialang.org/downloads/oldreleases/
2. Copy the link to the tar file. It should look something like this:
   1. https://julialang-s3.julialang.org/bin/linux/x64/1.9/julia-1.9.3-linux-x86_64.tar.gz
3. Back in the command line, download the tar file using
   1. wget https://julialang-s3.julialang.org/bin/linux/x64/1.9/julia-1.9.3-linux-x86_64.tar.gz
   2. ls # check whether you've downloaded it
   3. tar -xvzf julia-1.9.3-linux-x86_64.tar.gz # extract the tar
   4. ls # check whether it's been properly extracted, you should see a file like julia-1.9.3
   5. echo 'export PATH=julia-1.9.0/bin:$PATH' >> ~/.bashrc # add julia to the path and then save in .bashrc. The ~ means that .bashrc is in the home directory. If you've been messing with this step and your path is screwed up, which you can check using echo $PATH, you can use vi ~/.bashrc to view and edit the file
   6. source ~/.bashrc # add to source
   7. julia --version # should show you 1.9.3

## Using the salloc

**Overview:**
*https://engaging-web.mit.edu/eofe-wiki/slurm/srun/*

- opens up an interactive shell in the computing cluster that you can use like a nomrmal shell
- you can run julia directly in that shell but it IS based in the shell so unlike sbatch (where you're just monitoring the output of the CPU's) you can't close the shell
 
**Terminal code for salloc:**

sinfo
salloc -N 1 -n 4 -t 12:00:00 -C centos7 -p sched_any --mail-type=BEGIN,END --mail-user=nhirt@mit.edu

julia

cd("/home/nhirt/Slab_Scripts")
pwd()

using Pkg; Pkg.activate("."); Pkg.status()

include("Tributary_Areas/two_way_slab/executable.jl")

... or

cd("/home/nhirt/Slab_Scripts"); using Pkg; Pkg.activate("."); include("Tributary_Areas/two_way_slab/executable.jl")

## Batch

You run a slurm file from the ssh terminal (e.g. sbatch /path/to/file.slurm). Typically for a julia script it will look something like this:

   #!/bin/bash

   #SBATCH -n 4 # 4 cores
   #SBATCH -N 1 # 1 node
   #SBATCH -t 12:00:00 # max time, make sure to check sinfo
   #SBATCH -C centos7 # which OS?
   #SBATCH -p sched_any # which server?
   #SBATCH -o output_%j.txt # absolutely necessary for slurm to work
   #SBATCH -e error_%j.txt # absolutely necessary for slurm to work
   #SBATCH --mail-type=BEGIN,END # what to email
   #SBATCH --mail-user=nhirt@mit.edu # who to email

   /nfs/home2/nhirt/julia-1.9.3/bin/julia -t 4 Slab_Scripts/Tributary_Areas/two_way_slab/executable_grid.jl what to run
   
Note that you need to provide the julia directory in the same way you'd type "julia file.jl" in a regular terminal. The beginning of the julia file should contain all the commands you need to succeed, e.g.
   
   cd("/home/nhirt/Slab_Scripts"); 
   current_directory = pwd()
   println("Current directory: ", current_directory)

   using Pkg; 
   Pkg.activate(".");
   Pkg.status() 

   include("_two_way_slab.jl")

   begin
      ...
   end

## Parallelization

If you're just looping through independent processes start the loop with the decorator @threads (e.g. @threads for i in 1:lastindex(slab_types)). Make sure you also have using Base.Threads in your code to activate. 

The batch execution line is appended to with -t and the number of cores you want to use. if -n 4 (four cores) are being used, then you would type /path/to/julia -t 4 /path/to/file.jl

## Comments

- sinfo shows you what servers + nodes are open, their time limits etc.
- commands:
  - -N is the number of nodes
  - -n is the number of cores
  - -t is the time (make sure you adhere to the limit in sinfo)
  - -C is the operating system (eofe7 = centos7)
  - -p is the scheduling partition you want to run on (again, find under sinfo)
  - --mail-type is what kind of mail is sent/when you want to send the mail
  - --mail-user is the email you want to send the mail to
- you'll need to wait while resources are assigned to you
- julia opens julia once you've opened the node
- cd navigates to the directory that your Project.toml file is in (necessary for dependencies)
- pwd() is a way of checking that you're in the right directory
- using Pkg; Pkg.activate(".") activates the package in the directory you've navigated to
- ] status (or Pkg.status()) will show you packages that are available to you. Make sure this is what you expect
- include("path/to/file/executable.jl") runs the file you want
- the julia file behaves the same way it would in an IDE
