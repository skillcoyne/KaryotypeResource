# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

KaryotypeSource.create([{source: 'Mitelman',
                         source_short: 'mitelman',
                         url: 'http://cgap.nci.nih.gov/Chromosomes/Mitelman',
                         description: 'Mitelman Database of Chromosome Aberrations and Gene Fusions in Cancer'},
                        {source: 'NCBI SKY-FISH',
                         source_short: 'ncbi',
                         url: 'http://www.ncbi.nlm.nih.gov/sky/',
                         description: 'SKY/FISH public data'},
                        {source: 'University of Cambridge CGP',
                         source_short: 'cam',
                         url: 'http://www.path.cam.ac.uk/~pawefish/',
                         description: 'SKY Karyotypes and FISH analysis of Epithelial Cancer Cell Lines'}])

