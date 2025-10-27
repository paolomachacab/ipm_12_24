********************************************************************************
***** SDSN 2025 - CENSO 2012
********************************************************************************

clear all
set more off
version 17.0
set maxvar 32767

********************************************************************************
* 1️. CONFIGURACIÓN DE RUTAS GLOBALES
********************************************************************************

* La ruta se ajusta automáticamente al usuario que ejecuta el código
global path "C:\Users\PAOLO\Desktop\censo_2012"

* Directorios
global in  "$path"
global out "$path\_out"
global code "$path\_code"
global tbl "$path\_tbl"

* Crear carpetas si no existen
cap mkdir "$out"
cap mkdir "$code"
cap mkdir "$tbl"

display "Ruta principal definida: $path"

********************************************************************************
* 2️. IMPORTAR BASE PERSONA
********************************************************************************

capture confirm file "$in\PERSONA.csv"
if _rc == 0 {
    import delimited "$in\PERSONA.csv", clear varnames(1) encoding(UTF-8)
    compress
    save "$path\persona_2012.dta", replace
    display "Base PERSONA importada y guardada correctamente."
}
else {
    di as error "No se encontró el archivo PERSONA.csv en $path"
    exit
}

********************************************************************************
* 3️. IMPORTAR BASE VIVIENDA
********************************************************************************

capture confirm file "$in\VIVIENDA.csv"
if _rc == 0 {
    import delimited "$in\VIVIENDA.csv", clear varnames(1) encoding(UTF-8)
    compress
    save "$path\vivienda_2012.dta", replace
    display "Base VIVIENDA importada y guardada correctamente."
}
else {
    di as error "No se encontró el archivo VIVIENDA.csv en $path"
    exit
}

********************************************************************************
* 4UNIÓN DE BASES: PERSONA (m) : VIVIENDA (1)
********************************************************************************

use "$path\persona_2012.dta", clear
merge m:1 vivienda_ref_id using "$path\vivienda_2012.dta"

tab _merge

/*
Interpretación de _merge:
    1 → Personas sin vivienda asociada
    2 → Viviendas sin personas (desocupadas)
    3 → Coincidencia correcta (personas dentro de viviendas particulares)
*/

*merge m:1 vivienda_ref_id using "$path\vivienda_2012.dta"

 *   Result                      Number of obs
  *  -----------------------------------------
   * Not matched                       321,186
   *     from master                         0  (_merge==1)
   *     from using                    321,186  (_merge==2)

   * Matched                        10,059,856  (_merge==3)
    *-----------------------------------------

*
* tab _merge

 *  Matching result from |
  *                merge |      Freq.     Percent        Cum.
*------------------------+-----------------------------------
 *        Using only (2) |    321,186        3.09        3.09
 *           Matched (3) | 10,059,856       96.91      100.00
*------------------------+-----------------------------------
 *                 Total | 10,381,042      100.00


keep if _merge == 3
drop _merge

* Según variable p01: tipos 1–5 son viviendas particulares

keep if inrange(p01,1,5)

********************************************************************************
* 6️. GUARDAR BASE UNIFICADA FINAL
********************************************************************************

compress
save "$path\censo_2012_unido.dta", replace
display "✅ Base unificada guardada correctamente como censo_2012_unido.dta en $path"

********************************************************************************
* JEFE DE HOGAR POR SEXO
********************************************************************************
cap drop jefe_sexo
gen jefe_sexo = .
replace jefe_sexo = 1 if p23 == 1 & p24 == 1   // Jefa de hogar (mujer)
replace jefe_sexo = 0 if p23 == 1 & p24 == 2   // Jefe de hogar (hombre)

cap drop jefe_hogar
bys vivienda_ref_id: egen jefe_hogar = max(jefe_sexo)

label var jefe_hogar "Sexo del jefe/a del hogar (1=Mujer, 0=Hombre)"
label define jefe_lbl 0 "Hombre" 1 "Mujer"
label values jefe_hogar jefe_lbl

tab jefe_hogar, missing


*tab jefe_hogar, missing

 *  Sexo del |
 *jefe/a del |
 *     hogar |
 * (1=Mujer, |
 * 0=Hombre) |      Freq.     Percent        Cum.
*------------+-----------------------------------
 *    Hombre |  6,634,409       67.51       67.51
  *    Mujer |  3,155,610       32.11       99.62
   *       . |     37,070        0.38      100.00
*------------+-----------------------------------
 *     Total |  9,827,089      100.00


********************************************************************************
* JEFE DE HOGAR INDÍGENA
********************************************************************************
cap drop jefe_indigena
gen jefe_indigena = .
replace jefe_indigena = 1 if p23 == 1 & p29 == 1   // Jefe/a se autoidentifica como indígena
replace jefe_indigena = 0 if p23 == 1 & p29 == 2   // Jefe/a no indígena

cap drop jefe_indigena_v
bys vivienda_ref_id: egen jefe_indigena_v = max(jefe_indigena)

label var jefe_indigena_v "Jefe/a del hogar indígena (1=Sí, 0=No)"
label define indigena_lbl 0 "No indígena" 1 "Indígena"
label values jefe_indigena_v indigena_lbl

tab jefe_indigena_v, missing

*tab jefe_indigena_v, missing

 *Jefe/a del |
  *    hogar |
   *indígena |
    * (1=Sí, |
     * 0=No) |      Freq.     Percent        Cum.
*------------+-----------------------------------
*No indígena |  2,123,553       21.61       21.61
 *  Indígena |  1,887,139       19.20       40.81
  *        . |  5,816,397       59.19      100.00
*------------+-----------------------------------
 *     Total |  9,827,089      100.00


********************************************************************************
* JEFE DE HOGAR INDÍGENA POR SEXO
********************************************************************************
cap drop jefe_indigena_s
gen jefe_indigena_s = .
replace jefe_indigena_s = 1 if p23 == 1 & p29 == 1 & p24 == 1   // Mujer indígena
replace jefe_indigena_s = 0 if p23 == 1 & p29 == 1 & p24 == 2   // Hombre indígena

cap drop jefe_indigena_s_v
bys vivienda_ref_id: egen jefe_indigena_s_v = max(jefe_indigena_s)

label var jefe_indigena_s_v "Sexo del jefe indígena (1=Mujer, 0=Hombre)"
label values jefe_indigena_s_v jefe_lbl

tab jefe_indigena_s_v, missing

********************************************************************************
* JEFE DE HOGAR NO INDÍGENA POR SEXO
********************************************************************************
cap drop jefe_no_indigena
gen jefe_no_indigena = .
replace jefe_no_indigena = 1 if p23 == 1 & p29 == 2 & p24 == 1   // Mujer no indígena
replace jefe_no_indigena = 0 if p23 == 1 & p29 == 2 & p24 == 2   // Hombre no indígena

cap drop jefe_no_indigena_v
bys vivienda_ref_id: egen jefe_no_indigena_v = max(jefe_no_indigena)

label var jefe_no_indigena_v "Sexo del jefe no indígena (1=Mujer, 0=Hombre)"
label values jefe_no_indigena_v jefe_lbl

tab jefe_no_indigena_v, missing

********************************************************************************
* HOGAR CON AL MENOS UNA PERSONA CON DISCAPACIDAD
********************************************************************************
cap drop discapacitado
gen discapacitado = .
replace discapacitado = 1 if p22 == 1   // Hay persona con dificultad permanente
replace discapacitado = 0 if p22 == 2   // Ninguna persona con dificultad

cap drop discapacitado_v
bys vivienda_ref_id: egen discapacitado_v = max(discapacitado)

label var discapacitado_v "Hogar con al menos una persona con discapacidad (1=Sí, 0=No)"
label define disc_lbl 0 "Sin discapacidad" 1 "Con discapacidad"
label values discapacitado_v disc_lbl

tab discapacitado_v, missing
**************************************************************
* FIN DEL SCRIPT
**************************************************************

