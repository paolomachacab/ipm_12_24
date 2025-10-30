********************************************************************************
* SDSN 2025 - CENSO 2012
* Elaborado para análisis IPM municipal
* Versión: 1.0
* Última actualización: 2024
********************************************************************************

clear all
set more off
version 17.0
set maxvar 32767

********************************************************************************
* CONFIGURACIÓN DE RUTAS GLOBALES
********************************************************************************
global path "C:\Users\PAOLO\Desktop\censo_2012"
global in  "$path"
global out "$path\_out"
global code "$path\_code"
global tbl "$path\_tbl"

* Crear directorios si no existen
foreach dir in out code tbl {
    cap mkdir "`$`dir''"
}

display "Ruta principal definida: $path"

********************************************************************************
* IMPORTAR BASES ORIGINALES
********************************************************************************

*--- PERSONA ---
capture confirm file "$in\PERSONA.csv"
if _rc == 0 {
    import delimited "$in\PERSONA.csv", clear varnames(1) encoding(UTF-8)
    compress
    save "$path\persona_2012.dta", replace
    di as text "✔ Base PERSONA importada."
}
else {
    di as error "❌ No se encontró PERSONA.csv"
    exit
}

*--- VIVIENDA ---
capture confirm file "$in\VIVIENDA.csv"
if _rc == 0 {
    import delimited "$in\VIVIENDA.csv", clear varnames(1) encoding(UTF-8)
    compress
    save "$path\vivienda_2012.dta", replace
    di as text "✔ Base VIVIENDA importada."
}
else {
    di as error "❌ No se encontró VIVIENDA.csv"
    exit
}

*--- MUNICIPIO ---
capture confirm file "$in\MUNIC.csv"
if _rc == 0 {
    import delimited "$in\MUNIC.csv", clear varnames(1) encoding(UTF-8)
    compress
    save "$path\municipio_2012.dta", replace
    di as text "✔ Base MUNIC importada."
}
else {
    di as error "❌ No se encontró MUNIC.csv"
    exit
}

********************************************************************************
* UNIÓN DE BASES DE DATOS
********************************************************************************
use "$path\persona_2012.dta", clear

* Unir con vivienda
merge m:1 vivienda_ref_id using "$path\vivienda_2012.dta"
keep if _merge == 3
drop _merge

* Solo viviendas particulares
keep if inrange(p01,1,5)

* Unir con municipio
merge m:1 munic_ref_id using "$path\municipio_2012.dta"
keep if _merge == 3
drop _merge

compress
save "$path\censo_2012_unido.dta", replace
display "✅ Base unificada final creada: censo_2012_unido.dta"

********************************************************************************
* CARACTERÍSTICAS DEL JEFE DE HOGAR
********************************************************************************

*--- Sexo del jefe de hogar ---
cap drop jefe_sexo
gen jefe_sexo = .
replace jefe_sexo = 1 if p23 == 1 & p24 == 1   // Jefa de hogar (mujer)
replace jefe_sexo = 0 if p23 == 1 & p24 == 2   // Jefe de hogar (hombre)

cap drop jefe_hogar
bys vivienda_ref_id: egen jefe_hogar = max(jefe_sexo)

label var jefe_hogar "Sexo del jefe/a del hogar (1=Mujer, 0=Hombre)"
label define jefe_lbl 0 "Hombre" 1 "Mujer"
label values jefe_hogar jefe_lbl

*--- Jefe de hogar indígena ---
cap drop jefe_indigena
gen jefe_indigena = .
replace jefe_indigena = 1 if p23 == 1 & p29 == 1   // Jefe/a indígena
replace jefe_indigena = 0 if p23 == 1 & p29 == 2   // Jefe/a no indígena

cap drop jefe_indigena_v
bys vivienda_ref_id: egen jefe_indigena_v = max(jefe_indigena)

label var jefe_indigena_v "Jefe/a del hogar indígena (1=Sí, 0=No)"
label define indigena_lbl 0 "No indígena" 1 "Indígena"
label values jefe_indigena_v indigena_lbl

*--- Jefe indígena por sexo ---
cap drop jefe_indigena_s
gen jefe_indigena_s = .
replace jefe_indigena_s = 1 if p23 == 1 & p29 == 1 & p24 == 1   // Mujer indígena
replace jefe_indigena_s = 0 if p23 == 1 & p29 == 1 & p24 == 2   // Hombre indígena

cap drop jefe_indigena_s_v
bys vivienda_ref_id: egen jefe_indigena_s_v = max(jefe_indigena_s)
label var jefe_indigena_s_v "Sexo del jefe indígena (1=Mujer, 0=Hombre)"
label values jefe_indigena_s_v jefe_lbl

*--- Jefe no indígena por sexo ---
cap drop jefe_no_indigena
gen jefe_no_indigena = .
replace jefe_no_indigena = 1 if p23 == 1 & p29 == 2 & p24 == 1   // Mujer no indígena
replace jefe_no_indigena = 0 if p23 == 1 & p29 == 2 & p24 == 2   // Hombre no indígena

cap drop jefe_no_indigena_v
bys vivienda_ref_id: egen jefe_no_indigena_v = max(jefe_no_indigena)
label var jefe_no_indigena_v "Sexo del jefe no indígena (1=Mujer, 0=Hombre)"
label values jefe_no_indigena_v jefe_lbl

*--- Hogar con discapacidad ---
cap drop discapacitado
gen discapacitado = .
replace discapacitado = 1 if p22 == 1   // Persona con dificultad permanente
replace discapacitado = 0 if p22 == 2   // Sin dificultad

cap drop discapacitado_v
bys vivienda_ref_id: egen discapacitado_v = max(discapacitado)
label var discapacitado_v "Hogar con al menos una persona con discapacidad (1=Sí, 0=No)"
label define disc_lbl 0 "Sin discapacidad" 1 "Con discapacidad"
label values discapacitado_v disc_lbl

********************************************************************************
* DIMENSIÓN: PODER Y VOZ
********************************************************************************

*--- Analfabetismo ---
cap drop analfabetismo_ind
gen analfabetismo_ind = .
replace analfabetismo_ind = 1 if p25 >= 15 & p35 == 2
replace analfabetismo_ind = 0 if p25 >= 15 & p35 == 1
bys vivienda_ref_id: egen analfabetismo_hogar = max(analfabetismo_ind)
label var analfabetismo_hogar "Privación: analfabetismo (hogar)"

*--- Sin documento de identidad ---
cap drop sin_carnet_ind
gen sin_carnet_ind = .
replace sin_carnet_ind = 1 if p25 >= 6 & p27 == 2
replace sin_carnet_ind = 0 if p25 >= 6 & p27 == 1
bys vivienda_ref_id: egen sin_carnet_hogar = max(sin_carnet_ind)
label var sin_carnet_hogar "Privación: sin documento de identidad (hogar)"

*--- Comunicación ---
cap drop comunicacion_hogar
gen comunicacion_hogar = .
replace comunicacion_hogar = 1 if p17e == 2
replace comunicacion_hogar = 0 if p17e == 1
label var comunicacion_hogar "Privación: sin teléfono fijo ni celular"

********************************************************************************
* DIMENSIÓN: RECURSOS
********************************************************************************

*--- Agua potable ---
cap drop priv_agua_potable
gen priv_agua_potable = .
replace priv_agua_potable = 1 if inlist(p07,5,6,7)
replace priv_agua_potable = 0 if inlist(p07,1,2,3,4)
label var priv_agua_potable "Privación: hogar sin agua potable"

*--- Electricidad ---
cap drop priv_electricidad
gen priv_electricidad = .
replace priv_electricidad = 1 if inlist(p11,4,5)
replace priv_electricidad = 0 if inlist(p11,1,2,3)
label var priv_electricidad "Privación: hogar sin electricidad"

*--- Saneamiento básico ---
cap drop priv_saneamiento
gen priv_saneamiento = .
replace priv_saneamiento = 1 if p09 == 3
replace priv_saneamiento = 0 if inlist(p09,1,2)
label var priv_saneamiento "Privación: hogar sin saneamiento básico"

********************************************************************************
* DIMENSIÓN: OPORTUNIDADES Y ELECCIÓN
********************************************************************************

*--- Parto fuera de centro de salud ---
cap drop parto_no_salud_ind
gen parto_no_salud_ind = .

* Privación: mujeres 15-49 años con parto fuera de centro de salud
replace parto_no_salud_ind = 1 if p24 == 1 & inrange(p25,15,49) & inlist(p49b,2,3)

* No privación
replace parto_no_salud_ind = 0 if p24 == 1 & inrange(p25,15,49) & p49b == 1  // Centro salud
replace parto_no_salud_ind = 0 if p24 == 1 & inrange(p25,15,49) & p49b == 0  // No aplica
replace parto_no_salud_ind = 0 if p24 == 2                                   // Hombres
replace parto_no_salud_ind = 0 if p24 == 1 & (p25 < 15 | p25 > 49)           // Fuera rango

* Missings
replace parto_no_salud_ind = . if inlist(p49b,9,10,.)

* Colapsar a nivel hogar
bys vivienda_ref_id: egen parto_no_salud_hogar = max(parto_no_salud_ind)
label var parto_no_salud_hogar "Privación: parto fuera de centro de salud (hogar)"
label define parto_label 0 "No privado" 1 "Privado"
label values parto_no_salud_hogar parto_label

*--- Embarazo adolescente ---
cap drop embarazo_adolescente_ind
gen embarazo_adolescente_ind = .

* Privación: mujeres 15-19 años con al menos un hijo
replace embarazo_adolescente_ind = 1 if inrange(p25,15,19) & p24 == 1 & p46 > 0 & p46 < 98

* No privación
replace embarazo_adolescente_ind = 0 if inrange(p25,15,19) & p24 == 1 & inlist(p46,0,100)
replace embarazo_adolescente_ind = 0 if p24 == 2
replace embarazo_adolescente_ind = 0 if p24 == 1 & (p25 < 15 | p25 > 19)

* Missings
replace embarazo_adolescente_ind = . if inlist(p46,98,99,.)

* Colapsar a nivel hogar
bys vivienda_ref_id: egen embarazo_adolescente_hogar = max(embarazo_adolescente_ind)
label var embarazo_adolescente_hogar "Privación: embarazo adolescente (hogar)"

*--- Educación: niños que no asisten a la escuela ---
cap drop sin_asistencia
gen sin_asistencia = .
replace sin_asistencia = 1 if inrange(p25, 6, 19) & p36 == 4
replace sin_asistencia = 0 if inrange(p25, 6, 19) & inlist(p36,0,1,2,3)
replace sin_asistencia = 0 if (p25 < 6 | p25 > 19) 

cap drop asistencia_hogar
egen asistencia_hogar = max(sin_asistencia), by(vivienda_ref_id)
label var asistencia_hogar "Privación: niños 6-19 años no asisten a escuela"

********************************************************************************
* VERIFICACIÓN FINAL
********************************************************************************
display "=== VERIFICACIÓN DE VARIABLES CREADAS ==="

foreach var in jefe_hogar jefe_indigena_v discapacitado_v ///
               analfabetismo_hogar sin_carnet_hogar comunicacion_hogar ///
               priv_agua_potable priv_electricidad priv_saneamiento ///
               parto_no_salud_hogar embarazo_adolescente_hogar asistencia_hogar {
    di "`var':"
    tab `var', missing
}

display "✅ Procesamiento completado exitosamente"

* Guardar base final
save "$out\censo_2012_ipm_final.dta", replace

