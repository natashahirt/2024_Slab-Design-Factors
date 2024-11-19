#!/bin/bash

# Define the SLURM script and the maximum number of resubmissions
SLURM_SCRIPT="SlabDesignFactors/results/executable/executable.slurm"
MAX_RESUBMISSIONS=10
COUNTER=0

# Email for notifications
EMAIL="nhirt@mit.edu"

# Function to submit the job and get the job ID
submit_job() {
    JOB_ID=$(sbatch --parsable $SLURM_SCRIPT 2>&1)
    if [ $? -ne 0 ]; then
        echo "Failed to submit job. Exiting."
        echo -e "Job submission failed for $SLURM_SCRIPT\nError: $JOB_ID" | mail -s "SLURM Job Submission Error" $EMAIL
        exit 1
    fi
    echo "Submitted job $JOB_ID"
}

# Initial job submission
submit_job

# Loop to resubmit the job upon completion
while [ $COUNTER -lt $MAX_RESUBMISSIONS ]; do
    # Wait for the job to complete
    squeue --job $JOB_ID > /dev/null 2>&1
    while [ $? -eq 0 ]; do
        sleep 60  # Check every minute
        squeue --job $JOB_ID > /dev/null 2>&1
    done

    # Check the job's exit status
    JOB_STATE=$(sacct -j $JOB_ID --format=State --noheader | tr -d ' ')
    if [ "$JOB_STATE" == "FAILED" ]; then
        ERROR_LOG=$(sacct -j $JOB_ID --format=JobID,JobName,State,ExitCode --noheader)
        echo "Job $JOB_ID failed. Exiting."
        echo -e "Job $JOB_ID failed. Please check the logs.\nDetails:\n$ERROR_LOG" | mail -s "SLURM Job Failure" $EMAIL
        exit 1
    fi

    # Increment the counter
    COUNTER=$((COUNTER + 1))

    # Resubmit the job
    submit_job
done

echo "Reached maximum number of resubmissions: $MAX_RESUBMISSIONS"