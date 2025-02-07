process SAMPLE {

    tag { id }

    publishDir path: "${params.resultsDir}/samples",
               saveAs: { filename -> filename.replaceAll(/_sample/, '') },
               mode: 'copy',
               overwrite: 'true'

    input:
    tuple val(id), path(file), val(extension)

    output:
    tuple val(id), path("${id}_sample.${extension}"), emit: sampleFiles

    script:

    if (extension == 'bam')
        """
        samtools view \
            -@ ${task.cpus} \
            -s ${params.sample_fraction} \
            -b ${file} \
            -o ${id}_sample.bam
        """
    else if (extension == 'fastq.gz')
        """
        seqtk sample -s100 ${file} ${params.sample_fraction} | gzip > ${id}.fastq.gz
        """
    else
        error "Unsupported file extension: ${extension}"
}