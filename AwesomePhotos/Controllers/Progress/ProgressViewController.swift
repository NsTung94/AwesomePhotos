//
//  ProgressViewController.swift
//  AwesomePhotos
//
//  Created by Rasmus Petersen on 09/05/2019.
//

import Foundation
import UIKit

class ProgressViewController : UIViewController{
    
    @IBOutlet var tableview: UITableView!
    var p = ProgressTableViewCellControllerTableViewCell()
    var progressCells : [Progress] = []
    var cameraVC = CameraViewController()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        progressCells = addProgressCell()

    }

    func addProgressCell() -> [Progress]{
       
        var arr : [Progress] = []
        let newProgressObject = Progress(image : UIImage(named: "shutter")!, label: "IMG_GJP3B.JPG", progress : 0)

        arr.append(newProgressObject)
        return arr
    }
}

extension ProgressViewController : UITableViewDelegate, UITableViewDataSource{
    
    //CELLS
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return progressCells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let uploadView = progressCells[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ProgressTableViewCellControllerTableViewCell
        cell.populateTableCell(progressCell: uploadView)

        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        
        guard editingStyle == .delete else { return }
        progressCells.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic )
    }

    
    //HEADERS
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell") as! ProgressHeaderCellView
        return cell.contentView
        
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell") as! ProgressHeaderCellView
        return cell.bounds.height
        
    }
}
