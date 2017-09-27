#!/usr/bin/env nextflow

Channel
    .fromPath( params.input )
    .splitCsv()
    .flatten()
    .map { [ it.replaceAll(/.*\/|\.bam/, ''), it ] }
    .set { bamLinks }

process download {

    tag { id }

    publishDir path: "${params.resultsDir}/reads",
               mode: 'copy',
               overwrite: 'true'

    input:
    set val(id), val(link) from bamLinks

    output:
    set val(id), file("${id}.bam") into bamFiles

    script:
    """
    wget \
      --no-verbose \
      --no-use-server-timestamps \
      --continue \
      --output-document=${id}.bam \
      --no-check-certificate \
      --auth-no-challenge \
      --user=${params.username} \
      --password=${params.password} \
      --append-output=${id}.log \
      ${link}
    """
}

process sample {

    tag { id }

    publishDir path: "${params.resultsDir}/samples",
               saveAs: { filename -> filename.replaceAll(/_sample/, '') },
               mode: 'copy',
               overwrite: 'true'

    module params.samtools

    input:
    set val(id), file(bam) from bamFiles

    output:
    set val(id), file("${id}_sample.bam") into sampleFiles

    script:
    """
    samtools view \
        -s ${params.sample_fraction} \
        -b ${bam} \
        -o ${id}_sample.bam
    """
}

workflow.onComplete {
	println ( workflow.success ? "COMPLETED!" : "FAILED" )
}
