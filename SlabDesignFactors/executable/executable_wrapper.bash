#!/bin/bash

# Define the SLURM script and the maximum number of resubmissions
SLURM_SCRIPT="SlabDesignFactors/executable/executable.slurm"
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
    echo -e "Job $JOB_ID has been submitted successfully.\nSLURM Script: $SLURM_SCRIPT\n" | mail -s "SLURM Job Submitted" $EMAIL
}

# Initial job submission
submit_job

# Loop to resubmit the job upon completion
while [ $COUNTER -lt $MAX_RESUBMISSIONS ]; do
    echo "Monitoring job $JOB_ID..."

    # Wait for the job to complete
    while squeue --job $JOB_ID > /dev/null 2>&1; do
        sleep 60  # Check every minute
    done

    # Check the job's exit status
    JOB_STATE=$(sacct -j $JOB_ID --format=State --noheader | tr -d ' ')
    ERROR_LOG=$(sacct -j $JOB_ID --format=JobID,JobName,State,ExitCode --noheader)

    if [ "$JOB_STATE" == "FAILED" ]; then
        echo "Job $JOB_ID failed. Exiting."
        FULL_ERROR=$(sacct -j $JOB_ID --format=JobID,JobName,Partition,Account,State,ExitCode,MaxRSS,Elapsed,Timelimit --noheader)
        echo -e "Job $JOB_ID failed. Full details:\n$FULL_ERROR\n" | mail -s "SLURM Job Failure" $EMAIL
        exit 1
    elif [ "$JOB_STATE" == "COMPLETED" ]; then
        echo "Job $JOB_ID completed successfully."
        OUTPUT_FILE="output_${JOB_ID}.txt"
        ERROR_FILE="error_${JOB_ID}.txt"
        
        # Archive output and error files
        if [ -f $OUTPUT_FILE ]; then
            mv $OUTPUT_FILE outputs/
        fi
        if [ -f $ERROR_FILE ]; then
            mv $ERROR_FILE errors/
        fi
        
        echo -e "Job $JOB_ID completed successfully.\nArchived output to outputs/ and errors/." | mail -s "SLURM Job Completed" $EMAIL
    fi

    # Increment the counter
    COUNTER=$((COUNTER + 1))

    # Resubmit the job if the maximum resubmissions hasn't been reached
    if [ $COUNTER -lt $MAX_RESUBMISSIONS ]; then
        echo "Resubmitting job $COUNTER of $MAX_RESUBMISSIONS..."
        submit_job
    fi
done

echo "Reached maximum number of resubmissions: $MAX_RESUBMISSIONS"
echo -e "Job resubmission limit reached ($MAX_RESUBMISSIONS).\nNo further submissions will be made." | mail -s "SLURM Resubmission Limit Reached" $EMAIL
