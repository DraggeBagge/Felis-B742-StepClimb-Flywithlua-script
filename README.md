# Felis-B742-StepClimb-Flywithlua-script
Flywithlua script that automates what is otherwise a manual stepclimb procedure for the awesome Felis Boing 747-200.<br>
The script logic uses the same POH tables as those printed on the flight engineers station, including ISA deviation limitations. <br><br>

# Bug reports
Simply file an issue under the issues section of this repo and I or someone else will handle it in time

# Instructions
1.**Download script**
   - [Download the latest release ,lua file (click on me)](https://github.com/DraggeBagge/Felis-B742-StepClimb-Flywithlua-script/releases)
     
2. **Locate your X-Plane installation folder**  
   - Example paths:  
     - Windows: `C:\X-plane 12 (or 11)\`  
     - macOS: `/Applications/X-plane 12 (or 11)/`

3. **Open the `Resources` folder**  
   - Navigate to: `X-plane 12 (or 11)/Resources/plugins/`

4. **Verify FlyWithLuaNG is installed**  
   - Inside `plugins`, you should see a folder named `FlyWithLua`.  
   - If missing, download FlyWithLuaNG (google it) and install it first.

5. **Find the `Scripts` folder**  
   - Path: `X-plane 12 (or 11)/Resources/plugins/FlyWithLua/Scripts`

6. **Copy  script file**  
   - Place the downloaded `.lua` file into the `Scripts` folder.  
   - Example:  
     ```
     X-plane 12 (or 11)/Resources/plugins/FlyWithLua/Scripts/DSC_StepClimb_B742_Felis.lua
     ```

7. **Start your flight**  
   - Start the flight as usual and doublecheck that `Plugin -> FlyWithLua -> Macros -> DSC StepClimb B742 Felis` exists in the menu. If it does not, please revisit earlier installation steps.
   - Clicking on the macro above will open a pop-up menu in which you may enable the script. _NOTE!_ Enable the script after prerequisites in step 8 are met.

8. **Prerequisites for enabling this script**  
   - Autopilot              ON
   - Auto Thrust            ON
   - CRZ EPRL mode          ON
     
   - To sum the steps from above up... _be in initial cruise configuration_.  

9. **Enable the script**  
   - Sekect between 085 and Long Range Cruise (LRC) modes. Leave it on 085 if you don't know what to select.
   - Click on "Enable script"<br>
     <img width="584" height="284" alt="image" src="https://github.com/user-attachments/assets/94c262bf-3a21-46b1-b2a1-1808d1fa251b" />


10. **(optional) Go to sleep or do the house chores...**  
   - ... and don't forget to check back on the plane prior to descent!

# Thank you
Many thanks to the following people that helped me get this script up and running through testing & advice:<br><br>
_Felis, nuke, JulietAlphaSierra4, apn (.org), triplemon (.org), sirtoper (.org)_
