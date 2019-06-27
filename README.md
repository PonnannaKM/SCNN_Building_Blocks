# SCNN_Building_Blocks
Stochastic convolution neural networks building blocks

The popular LeNet-5 CNN was developed completely from ground using stochastic computing circuits. These cicruits are developed in VHDL and contains generics which
can be used to change accordingly for newer designs.
For better understanding on the functionality of these circuits you can request me for more details @ ponnanna.kmc@gmail.com
The repository contains following discrete stochastic computing blocks using which a complete Stochastic Convolution neural Netwrok can be designed.
(1) Stochastic Mutlipliers | File Name : stochastic_multipliers.vhd
(2) Store Buffer | File Name : store_buffer.vhd
(3) Stochastic Sigmoid Activation Function | File Name : stochastic_sigmoid.vhd
(4) Stochastic Max Pooling | File Name : stochastic_max.vhd
(5) Stochastic Number Generators : SNG36, SNG12, SNG7, SNG4 | File Names : sng_36.vhd, sng_12.vhd, sng_7.vhd, sng_4.vhd
(6) Parallel Adders : 26bit Input PA, 32bit Input PA, 40bit Input PA, 42bit Input PA  | File Names : bit_parallel_counter_26.vhd, bit_parallel_counter_32.vhd,
    bit_parallel_counter_40.vhd, bit_parallel_counter_42.vhd
(7) Classifier | File Name : classifier.vhd
(8) Stochastic MAC Unit | File Name : mac_84.vhd
(9) Parameter Buffer | File Name : param_buffer.vhd
(10) Stochastic Computing Neuron | sc_neuron_type1
(11) SCNN_config_control_IP | 
