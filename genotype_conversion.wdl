task bgen_to_vcf {

	File bgen_file
	String? variant_range_filter = ""
	String outfile = basename(bgen_file, ".bgen")
	Int? memory = 10
	Int? disk = 20

	command {
		$QCTOOL \
			-g ${bgen_file} \
			-incl-range ${variant_range_filter} \
			-og ${outfile}.vcf.gz
	}

	runtime {
		docker: "kwesterman/dosage-interconversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_vcf = "${outfile}.vcf.gz"
	}
}

task vcf_to_bgen {

	File vcf_file
	String? variant_range_filter = ""
	String outfile = basename(vcf_file, ".vcf.gz")
	Int? memory = 10
	Int? disk = 20

	command {
		$QCTOOL \
			-g ${vcf_file} \
			-incl-range ${variant_range_filter} \
			-og ${outfile}.bgen \
			-os ${outfile}.sample
	}

	runtime {
		docker: "kwesterman/dosage-interconversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_bgen = "${outfile}.bgen"
		File out_sample = "${outfile}.sample"
	}
}

task vcf_to_minimac {

	File vcf_file
	#File? info_file
	String outfile = basename(vcf_file, ".vcf.gz")
	Int? memory = 10
	Int? disk = 20

	command {
		$DosageConvertor \
			--vcfDose ${vcf_file} \
			--type mach \
			--format 1 \
			--prefix ${outfile}
		gunzip < "${outfile}.mach.dose.gz" | tr '\t' ' ' > "${outfile}.mach.dose"
	}
			#${"--info " + info_file} \

	runtime {
		docker: "kwesterman/dosage-interconversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_minimac_gz = "${outfile}.mach.dose.gz"
		File out_minimac = "${outfile}.mach.dose"
		File out_info = "${outfile}.mach.info"
	}
}

task minimac_to_mmap {

	File dose_file
	File info_file
	String outfile = basename(dose_file, ".dose.gz")
	Int? memory = 10
	Int? disk = 20

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
		docker: "kwesterman/dosage-interconversion:latest"
		memory: "${memory} GB"
		disks: "local-disk ${disk} HDD"
	}

	output {
		File out_mmap = "${outfile}_bin"
	}
}


workflow convert {

	String conversion
	Array[File] input_files
	Array[File]? info_files
	String? variant_range_filter
	String? memory
	String? disk

	if(conversion == "bgen2vcf") {
		scatter (input_file in input_files) {
			call bgen_to_vcf {
				input:
					bgen_file = input_file, 
					variant_range_filter = variant_range_filter,
					memory = memory,
					disk = disk
			}
		}

		output {
			Array[File]? converted_vcf_files = bgen_to_vcf.out_vcf
		}
	}

	if(conversion == "vcf2bgen") {
		scatter (input_file in input_files) {
			call vcf_to_bgen {
				input:
					vcf_file = input_file, 
					variant_range_filter = variant_range_filter,
					memory = memory,
					disk = disk
			}
		}

		output {
			Array[File]? converted_bgen_files = vcf_to_bgen.out_bgen
			Array[File]? converted_sample_files = vcf_to_bgen.out_sample
		}
	}

	if(conversion == "vcf2minimac") {
		scatter (input_file in input_files) {
			call vcf_to_minimac {
				input:
					vcf_file = input_file, 
					memory = memory,
					disk = disk
					#info_file = info_file
			}
		}

		output {
			Array[File]? converted_dose_files = vcf_to_minimac.out_minimac
			Array[File]? converted_info_files = vcf_to_minimac.out_info
		}
	}

	if(conversion == "minimac2mmap") {

		Array[File] info_files_nonoptional = select_first([info_files, []])
		Array[Pair[File,File]] filesets = zip(input_files, info_files_nonoptional)

		scatter (fileset in filesets) {
			call minimac_to_mmap {
				input:
					dose_file = fileset.left,
					info_file = fileset.right, 
					memory = memory,
					disk = disk
			}
		}

		output {
			Array[File]? converted_mmap_files = minimac_to_mmap.out_mmap
		}
	}

	parameter_meta {
		conversion: "String representing the requested conversion. Current options include: bgen2vcf, vcf2bgen, vcf2minimac, and minimac2mmap."
		input_files: "Array of genotype dosage files (currently, in VCF or .bgen format)."
		info_files: "Array of variant info files (used in the Minimac to MMAP conversion)." 
		variant_range_filter: "Optional string for variant filtering. Format: chr:start-stop (e.g. 2:100000-500000)."
		memory: "Requested memory (in GB)."
		disk: "Requested disk space (in GB)."
	}

	meta {
                author: "Kenny Westerman"
                email: "kewesterman@mgh.harvard.edu"
		decription: "Convert imputed genotype data file formats for use in downstream GxE testing, with Minimac4 VCF as the assumed base format. Currently implements VCF to .bgen/Minimac dose/MMAP and .bgen to VCF."
	}
}
