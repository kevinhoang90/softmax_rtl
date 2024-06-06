# SOFTMAX FUNCTION WITH VERILOG 
### 1. Softmax
    - Softmax is an activation function and is used in the last layer in the neural network like CNN, DNN,...
![Softmax regression model as a neural network ](illustrating%20images/soft_max_neural.png)

### 2. Mathetical Model
    - Input of softmax function is real vector z = {z1...zC} with C is number of class.
    - Output of softmax function is real(probability) vector a = {a1...aC} and sum of vector a is equal to 1.
![Mathetical Model of Softmax function](illustrating%20images/softmax_mathetical_model.png)

### 3. Hardware Implementation Approach
    - The simplest way is to directly implement the initial softmax expression. But it has some problems.
        + Firstly: Since zi is a real number, it can lead to the value of exp(zi) becoming too large, thus consuming more resouces to store this value.
        + Next: In this mathetical model, there is a division operator, which also consumes a large mount of resouces to perform.
    - Improving the aforementioned problems.
        + Downscaling value of exp(zi) to exp(zi - zmax) with zmax is max value of vector input z.
        + Transfroming the expression for removing the division operator.
![transfrom](illustrating%20images/transform_model.png)
### 4. Specification
- **Block diagram of softmax**

![block](illustrating%20images/block.png) 

    - This module captures the 32-bit floating point single precision input, converting it to 16-bit.

  
### 5. Implement and Simulation result
    -   The design was synthesized and implemented on Xilinx's Zedboard using Vivado 2018.3.
#### 5.1 Implement
    -  Implement report (constraint clock with 14ns cycle).
![hardware resouce](illustrating%20images/hardware_resource.png)
![timing](illustrating%20images/timing.png)
#### 5.2 Simulation
    -   the module was simulated with the input vector X = {-4,541; -4,22; -0,464; 4,684; 3,524}
![alt text](illustrating%20images/simulation.png)

    -   The image below shows the softmax hardware and softmax software output. 
    -   Max error with a sample input above is 3.e-10. 
![alt text](illustrating%20images/hardware_software_result.png)
### 6. Experiment - [Project Source](https://drive.google.com/drive/folders/1HuWx-jO9p7ZGT83h_ViIQRIWQ5I0vAsK?usp=drive_link)
#### 6.1 Package IP
    -   RTL code was packaged with slave AXI4-Lite, slave and master AXI4-Stream into a IP core. And it was intergated into a SOC.

![package_ip](illustrating%20images/softmax_ip.png)
#### 6.2 Intergrated into SOC 
    -   The image below shows the SOC with Zynq PS, DMA IP, Softmax IP and some other blocks.
    -   SOC EXECUTION FLOW: 
        +   Input data will be initialized on DDR.
        +   DMA IP reads it and sends to Softmax IP through AXI4-Stream Master. 
        +   After Softmax IP computes completely, the output data will be sent to DMA IP through AXI4-Stream as well.
        +   DMA IP transfers that data into DDR.
![soc](illustrating%20images/SOC.png)

    -   ILA (Intergrated Logic Analyzer) was used to monitor AXI4-Stream interface in Softmax IP.
### 7. Result
#### 7.1 Input
    -   Input in Simulation
![alt text](illustrating%20images/in_simulation.png)
    
    -   Input in ILA tool.
![alt text](illustrating%20images/in_ILA.png)
#### 7.2 Output
    -   Output in Simulation.
![alt text](illustrating%20images/out_simulation.png)

    -   Output in ILA tool.
![alt text](illustrating%20images/out_ILA.png)
    
    -   The data line of AXI4-Stream has 32 bits but only the first 16 bits was used to represent data.
###  8. Conclusion
    -   With all of the above results, We can conclude that the module hardware perform the Softmax function correctly.