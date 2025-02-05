#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Import modules
include { DOWNLOAD } from './modules/download'
include { SAMPLE } from './modules/sample'

// Define input channel
ch_download_input = Channel
    .fromPath(params.input)
    .splitCsv()
    .flatten()
    .map { link -> 
        def fileName = link.tokenize('/')[-1]  // Get the filename from the URL
        def extension = fileName.endsWith('.tar.gz') ? 'tar.gz' : fileName.tokenize('.')[-1]  // Get extension
        def baseName = fileName.replaceFirst(/\.(tar\.gz|bam)$/, '')  // Remove extension
        [baseName, link, extension]
    }

// Main workflow
workflow {

    // Download NGS files
    ngsFiles = DOWNLOAD( ch_download_input )

    ngsFilesSamples = ngsFiles
        .map { id, files -> 
            files.collect { file -> 
                def name = file.name // Get the filename
                def extension = name.endsWith('.fastq.gz') ? 'fastq.gz' : name.tokenize('.')[-1] // Get extension
                name = name.replaceFirst(/\.(fastq\.gz|bam)$/, '') // Remove extension
                tuple(name, file, extension) 
            }
        }
        .flatMap { it -> it }

    // Sample NGS files
    sampleFiles = SAMPLE( ngsFilesSamples )

}

workflow.onComplete {
	println ( workflow.success ? "COMPLETED!" : "FAILED" )
}
