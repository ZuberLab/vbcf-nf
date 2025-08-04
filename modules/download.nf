process DOWNLOAD {

    tag { id }

    publishDir path: "${params.resultsDir}/reads",
               mode: 'copy',
               overwrite: 'true'

    input:
    tuple val(id), val(link), val(extension)

    output:
    tuple val(id), path("${id}{.bam,_R1.fastq.gz,_R2.fastq.gz}"), emit: ngsFiles

    script:
    """
    wget \
      --no-verbose \
      --no-use-server-timestamps \
      --continue \
      --output-document=${id}.${extension} \
      --no-check-certificate \
      --auth-no-challenge \
      --user=${params.username} \
      --password=${params.password} \
      --append-output=${id}.log \
      ${link}

    # If the downloaded file is a tar.gz, extract it
    if [[ "${extension}" == "tar.gz" ]]; then
        tar -xzvf ${id}.${extension}
        rm ${id}.${extension}

        find . -type f -name '*_R1_*.fastq.gz' -exec mv {} . \\;
        cat *_R1*.fastq.gz >> ${id}_R1.fastq.gz
        rm *_R1_*.fastq.gz

        if [[ "${params.paired_end}" == "false" ]]; then
            mv ${id}_R1.fastq.gz ${id}.fastq.gz
        else
            find . -type f -name '*_R2_*.fastq.gz' -exec mv {} . \\;
            cat *_R2_*.fastq.gz >> ${id}_R2.fastq.gz
            rm *_R2_*.fastq.gz
        fi
    fi

    """
}