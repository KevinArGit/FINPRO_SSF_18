# FINPRO_SSF_18

## I. Introduction to the problem and the solution

Maintaining a comfortable temperature can help well-being, rest, comfort, and productivity. To avoid expensive operational cost and greenhouse gas emissions, fans are better alternatives to air conditioners.  

This project wishes to produce products that, energy-efficient, automated, cost-effective, and have low greenhouse gas emission. These systems utilize fan and ventilation as a method to circulate cool air and lower the temperatures.

## II. Hardware design and implementation details

The hardware design involves creating a functional circuit using essential parts that integrate into each other well using:  
- power supply
- two Arduino microcontrollers
- a temperature sensor
- a cooling fan
- a keypad
- LCD display  

The schematic, a graphical representation of this design, shows the connectionL temperature sensors to digital pins, motor drivers to PWM pins, and LCD using I2C communication. During this design, it became apparent that Arduiono don’t have enough pins. Therefore, it's decided to use a slave Arduino to manage the keypad input, while the master manages the sensor and fan output.

![proteus schematics part 1](/images/proteus-1.png)
![proteus schematics part 2](/images/proteus-2.png)

## III. Software implementation details

The software development goal is to write and optimize code to ensure the system accurately monitors temperature and adjust fan speeds accordingly. By programming both Arduino with Assembly programming language. This process is then broken into several stages. Such as, sensor data acquisition, control logic, and user interface management. Sensor and data acquisition and control logic is done in the master Arduino while the user interface management is done with the help of slave Arduino too.

![Master Arduino Flowchart](/images/flowchart-master.png)
![Master Arduino Flowchart](/images/flowchart-slave.png)

## IV. Test results and performance evaluation

This testing phase has a goal of verifying that all components of the systems are functioning as it is supposed to be. Testing can be done for each component or for the system as a whole. The components that are in need of testing are, temperature sensors, fans, arduino, keypad, and LED display. But, the primary testing is the temperature sensors and user interface.  

The result presents the finding of the testing phase, which aimed to verify the functionality of components in the system. By primarily, focusing on the temperature sensors and user interface.

![Final Product](/images/rangkaian-asli.png)

## V. Conclusion and future work

While areas for improvement have been identified, such as refining control algorithms for enhanced precision
and exploring advanced sensor integration, the successful development and testing of the automatic room cooler lay a solid foundation for its future refinement and adoption. As efforts continue to optimize its design, the system holds promise for widespread deployment, offering tangible benefits in terms of indoor comfort, energy conservation, and environmental stewardship.