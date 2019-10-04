task bgen_to_vcf {

	#File bgen_pattern  # Can include "#" character as chromosome wildcard
	File bgen_file
	String outfile = basename(bgen_file, ".bgen")

	command {
		$QCTOOL \
			-g ${bgen_file} \
			-og ${outfile}.vcf.gz
	}

	runtime {
		docker: "kwesterman/genotype-interconversion:latest",
		memory: "${memory} GB"
	}

	output {
		File out = "${outfile}.vcf.gz"
	}
}

task vcf_to_bgen {

	#File vcf_pattern  # Can include "#" character as chromosome wildcard
	File vcf_file
	String outfile = basename(vcf_file, ".vcf.gz")

	command {
		$QCTOOL \
			-g ${vcf_file} \
			-og ${outfile}.bgen
	}

	runtime {
		docker: "kwesterman/genotype-interconversion:latest",
		memory: "${memory} GB"
	}

	output {
		File out = "${outfile}.bgen"
	}
}

task vcf_to_minimac {

	File vcf_file
	#File? info_file
	String outfile = basename(vcf_file, ".vcf.gz")

	command {
		$DosageConvertor \
			--vcfDose ${vcf_file} \
			--type mach \
			--format 1 \
			--prefix ${outfile}
	}
			#${"--info " + info_file} \

	runtime {
		docker: "kwesterman/genotype-interconversion:latest",
		memory: "${memory} GB"
	}

	output {
		File out = "${outfile}.mach.dose.gz"
		File info_out = "${outfile}.mach.info"
	}
}

task minimac_to_mmap {

	File dose_file
	File info_file
	String outfile = basename(dose_file, ".dose.gz")

	command {
		$MMAP \
			--mach_dose2mmap \
			--mach_info_filename ${info_file} \
			--mach_dose_filename ${dose_file} \
			--binary_output_filename ${outfile}_bin_SxM

		$MMAP \
			--transpose_binary_genotype_file \
			--binary_input_filename ${outfile}_bin_SxM \
			--binary_output_filename ${outfile}_bin
	}

	runtime {
		docker: "kwesterman/genotype-interconversion:latest"
	}

	output {
		File out = "${outfile}_bin",
		memory: "${memory} GB"
	}
}


workflow convert {

	String conversion
	Array[File] input_files
	Array[File]? info_files
	String memory

	if(conversion == "bgen2vcf") {
		scatter (input_file in input_files) {
			call bgen_to_vcf {
				input:
					bgen_file = input_file, 
					memory = memory
			}
		}

		#output {
		#	File outfile = bgen_to_vcf.out
		#}
	}

	if(conversion == "vcf2bgen") {
		scatter (input_file in input_files) {
			call vcf_to_bgen {
				input:
					vcf_file = input_file, 
					memory = memory
			}
		}

		#output {
		#	File outfile = vcf_to_bgen.out
		#}
	}

	if(conversion == "vcf2minimac") {
		scatter (input_file in input_files) {
			call vcf_to_minimac {
				input:
					vcf_file = input_file, 
					memory = memory
					#info_file = info_file
			}
		}

		#output {
		#	File minimac_outfile = vcf_to_minimac.out
		#}
	}

	if(conversion == "minimac2mmap") {

		Array[File] info_files_nonoptional = select_first([info_files, []])
		Array[Pair[File,File]] filesets = zip(input_files, info_files_nonoptional)

		scatter (fileset in filesets) {
			call minimac_to_mmap {
				input:
					dose_file = fileset.left,
					info_file = fileset.right, 
					memory = memory
			}
		}

		#output {
		#	File mmap_outfile = vcf_to_mmap.out
		#}
	}
}